#!/usr/bin/env node
/*
 * Imports a translation from the Google translation sheet into this repo.
 *
 *   npm run import -- <sheet url>        (or: node import.js <sheet url>)
 *
 * <sheet url> is the address of one language tab (the one with ?gid=... or
 * #gid=...) of the spreadsheet; the sheet must be viewable by link. A path to
 * an exported CSV file works too.
 *
 * The script
 *   - reads the language code from cell C2 of the tab,
 *   - adds a new resources-<code> folder (after asking) if there is none,
 *   - otherwise shows what differs between the sheet and
 *     resources-<code>/strings.xml and settingstrings.xml and asks whether to
 *     use the sheet's version (all changes, or one by one).
 *
 * Options:  --yes      do not ask, apply everything
 *           --dry-run  only show what would change
 *           --dir <d>  use <d> as the repository root (default: this folder)
 *
 * After writing, it offers to run ./filter.sh, which creates the manifest,
 * jungle and size folders of a new translation and refreshes the font filters
 * (the characters a font must contain) of all translations.
 */
const fs = require('fs');
const path = require('path');
const readline = require('readline/promises');
const { spawnSync } = require('child_process');

const args = process.argv.slice(2);
const flag = (name) => { const i = args.indexOf(name); if (i >= 0) { args.splice(i, 1); return true; } return false; };
const option = (name) => { const i = args.indexOf(name); if (i >= 0) { const v = args[i + 1]; args.splice(i, 2); return v; } return null; };
const YES = flag('--yes');
const DRY = flag('--dry-run');
const ROOT = path.resolve(option('--dir') || __dirname);
const source = args[0];

const tty = process.stdout.isTTY;
const paint = (code, s) => (tty ? `\x1b[${code}m${s}\x1b[0m` : s);
const red = (s) => paint(31, s), green = (s) => paint(32, s), dim = (s) => paint(2, s), bold = (s) => paint(1, s), yellow = (s) => paint(33, s);

function die(msg) { console.error(red('Error: ') + msg); process.exit(1); }

// ---------------------------------------------------------------- reading

async function readSheet(src) {
  if (!src) die('Usage: npm run import -- <sheet url>');
  if (fs.existsSync(src)) return fs.readFileSync(src, 'utf8');
  const id = /\/spreadsheets\/d\/([\w-]+)/.exec(src);
  if (!id) die('That does not look like a Google Sheets address: ' + src);
  const gid = /[#?&]gid=(\d+)/.exec(src);
  const url = `https://docs.google.com/spreadsheets/d/${id[1]}/export?format=csv` + (gid ? `&gid=${gid[1]}` : '');
  let res;
  try { res = await fetch(url); } catch (e) { die('Could not fetch the sheet: ' + e.message); }
  const type = res.headers.get('content-type') || '';
  if (!res.ok || !type.includes('csv')) {
    die(`Could not read the sheet (HTTP ${res.status}, ${type}). Is it shared so that anyone with the link can view it?`);
  }
  return res.text();
}

function parseCsv(text) {
  const rows = []; let row = [], field = '', quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"') { if (text[i + 1] === '"') { field += '"'; i++; } else quoted = false; }
      else field += c;
    } else if (c === '"') quoted = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); rows.push(row); row = []; field = ''; }
    else if (c !== '\r') field += c;
  }
  if (field || row.length) { row.push(field); rows.push(row); }
  return rows;
}

// ---------------------------------------------------------------- xml

const unescapeXml = (s) => s.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&');
const escapeXml = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const STRING_RE = /<string id="([^"]+)">([\s\S]*?)<\/string>/g;

function readStrings(text) {
  const map = {};
  for (const m of text.matchAll(STRING_RE)) map[m[1]] = unescapeXml(m[2]);
  return map;
}

function setString(text, id, value, order) {
  const element = `<string id="${id}">${escapeXml(value)}</string>`;
  const existing = new RegExp(`<string id="${id}">[\\s\\S]*?</string>`);
  if (existing.test(text)) return text.replace(existing, () => element);   // function: value may contain $1$
  // new string: put it after the closest preceding id of the standard order
  const present = readStrings(text);
  for (let i = order.indexOf(id) - 1; i >= 0; i--) {
    if (order[i] in present) {
      const prev = new RegExp(`(<string id="${order[i]}">[\\s\\S]*?</string>)`);
      return text.replace(prev, (m) => `${m}\n  ${element}`);
    }
  }
  return text.replace('<resources>', () => `<resources>\n  ${element}`);
}

// the app splits a minute string into top/middle/bottom lines; compare like the app does
function lines(value) {
  const first = value.indexOf('\t');
  if (first < 0) return ['', value, ''];
  let l0 = '', l1 = value.slice(0, first), l2 = value.slice(first + 1);
  const second = l2.indexOf('\t');
  if (second >= 0) { l0 = l1; l1 = l2.slice(0, second); l2 = l2.slice(second + 1); }
  return [l0, l1, l2];
}
const isMin = (id) => /^min\d+$/.test(id);
const same = (id, a, b) => (isMin(id) ? lines(a).join('\t') === lines(b).join('\t') : a.trim() === b.trim());
const show = (id, v) => (isMin(id) ? lines(v).map((l) => l || '·').join(dim(' | ')) : v);

// ---------------------------------------------------------------- main

async function main() {
  const rows = parseCsv(await readSheet(source));
  const code = ((rows[1] || [])[2] || '').trim().normalize('NFC');
  if (!/^[\p{L}\p{N}]{2,5}$/u.test(code)) die(`Cell C2 should contain the language code, found: '${code}'`);

  const file = (dir, name) => path.join(ROOT, dir, name);
  const baseStrings = fs.readFileSync(file('resources-eng', 'strings.xml'), 'utf8');
  const baseSettings = fs.readFileSync(file('resources', 'settingstrings.xml'), 'utf8');
  const stringsOrder = Object.keys(readStrings(baseStrings));
  const settingsOrder = Object.keys(readStrings(baseSettings));
  const fromBase = { ...readStrings(baseSettings), ...readStrings(baseStrings) };

  const dir = `resources-${code}`;
  const isNew = !fs.existsSync(file(dir, 'strings.xml'));
  const oldStrings = isNew ? fromBase : readStrings(fs.readFileSync(file(dir, 'strings.xml'), 'utf8'));
  const oldSettings = isNew || !fs.existsSync(file(dir, 'settingstrings.xml')) ? readStrings(baseSettings)
    : readStrings(fs.readFileSync(file(dir, 'settingstrings.xml'), 'utf8'));
  const old = { ...oldSettings, ...oldStrings };

  // ids of the sheet (column B) -> value (C), minute strings = C, D, E joined by tabs
  const sheet = {};
  for (const r of rows.slice(2)) {
    let id = (r[1] || '').trim();
    if (id === 'Watch face name') id = 'AppName';
    if (!id || !(id in fromBase || /^hour(1[3-9]|2[0-3])$/.test(id))) continue;
    const cells = (isMin(id) ? [r[2], r[3], r[4]] : [r[2]]).map((c) => (c || '').trim());
    sheet[id] = isMin(id) ? (cells.some(Boolean) ? cells.join('\t') : '') : cells[0];
  }

  const missing = [], warnings = [], wanted = {};
  const final = (id) => {            // sheet value, else what we have, else English
    if (sheet[id]) return sheet[id];
    if (id in old && !isNew) return old[id];
    missing.push(id);
    return fromBase[id];
  };
  for (const id of Object.keys(fromBase)) {
    if (/^dateFormatDay|^dateFormatMonth/.test(id)) continue;      // neutral labels, not in the sheet
    if (/^hour(1[3-9]|2[0-3])$/.test(id)) continue;
    wanted[id] = final(id);
  }
  // 13..23: copies of 1..11 unless the sheet (or the translation) has own words for the afternoon
  const sheetHasAfternoon = Object.keys(sheet).some((id) => /^hour1[3-9]|^hour2[0-3]/.test(id));
  for (let h = 13; h <= 23; h++) {
    const id = 'hour' + h, copy = wanted['hour' + (h - 12)];
    if (sheetHasAfternoon) wanted[id] = sheet[id] || copy;
    else if (isNew || !(id in old) || old[id].trim() === (old['hour' + (h - 12)] || '').trim()) wanted[id] = copy;
  }

  for (const id of Object.keys(wanted)) {
    const v = wanted[id];
    if (isMin(id) && id in sheet && !/\$[12]\$/.test(v)) warnings.push(`${id}: no $1$ or $2$ in '${v}'`);
    if (/^hour\d+$|^noon$|^midnight$/.test(id) && v.includes('$')) warnings.push(`${id}: contains '$'`);
    if (/\n/.test(v)) warnings.push(`${id}: contains a line break`);
  }

  console.log(bold(`Sheet: language code '${code}', ${Object.keys(sheet).length} strings read`));
  if (missing.length) console.log(yellow(`Blank or missing in the sheet, ${isNew ? 'English used' : 'kept (or English if new)'}: `) + [...new Set(missing)].join(', '));
  warnings.forEach((w) => console.log(yellow('Warning: ') + w));

  // ---- what changes
  const changes = [];
  for (const id of Object.keys(wanted)) {
    if (id in old === false) changes.push({ id, old: null, new: wanted[id] });
    else if (!same(id, old[id], wanted[id])) changes.push({ id, old: old[id], new: wanted[id] });
  }

  if (isNew) {
    console.log(`\nThere is no translation '${code}' yet.`);
    if (DRY) return console.log('Dry run, nothing written.');
    if (!(await confirm(`Add the new translation ${dir}?`, false))) return console.log('Nothing written.');
  } else {
    if (!changes.length) return console.log(green(`\n${dir} is already up to date with the sheet.`));
    console.log(`\n${dir} exists. ${changes.length} differences (${red('- repo')}, ${green('+ sheet')}):\n`);
    for (const c of changes) {
      console.log(bold(c.id));
      if (c.old !== null) console.log(red('  - ') + show(c.id, c.old));
      console.log(green('  + ') + show(c.id, c.new));
    }
    if (DRY) return console.log('\nDry run, nothing written.');
    const answer = YES ? 'y' : await ask(`\nUse the sheet's version? [y]es all / [n]o / [i]ndividually: `);
    if (answer === 'n' || answer === '') return console.log('Nothing written.');
    if (answer === 'i') {
      const kept = [];
      for (const c of changes) {
        console.log('\n' + bold(c.id));
        if (c.old !== null) console.log(red('  - ') + show(c.id, c.old));
        console.log(green('  + ') + show(c.id, c.new));
        if (await confirm('Use this?', false)) kept.push(c);
      }
      changes.splice(0, changes.length, ...kept);
      if (!changes.length) return console.log('Nothing written.');
    } else if (answer !== 'y') return console.log('Nothing written.');
  }

  // ---- write
  fs.mkdirSync(file(dir, ''), { recursive: true });
  const write = (name, template, order) => {
    const target = file(dir, name);
    let text = fs.existsSync(target) ? fs.readFileSync(target, 'utf8') : template;
    for (const id of Object.keys(wanted)) {
      if (!order.includes(id)) continue;                            // belongs to the other file
      if (!isNew && !changes.some((c) => c.id === id)) continue;    // not accepted / unchanged
      text = setString(text, id, wanted[id], order);
    }
    fs.writeFileSync(target, text);
  };
  write('strings.xml', baseStrings, stringsOrder);
  write('settingstrings.xml', baseSettings, settingsOrder);
  console.log(green(`\nWrote ${dir}/strings.xml and ${dir}/settingstrings.xml (${changes.length || Object.keys(wanted).length} strings).`));

  if (await confirm(isNew ? 'Run ./filter.sh now (creates manifest, jungle and size folders, updates font filters)?'
    : 'Run ./filter.sh now (updates the font filters in case of new characters)?', true)) {
    if (!fs.existsSync(path.join(ROOT, 'filter.sh'))) console.log('No filter.sh in ' + ROOT);
    else spawnSync('./filter.sh', { cwd: ROOT, stdio: 'inherit' });
  }
  console.log('\nNext: review with git diff' + (isNew ? ', build with ./build.sh ' + code + ', and after publishing to the store add the app id to translations.json and pages/index.html.' : ' and build with ./build.sh ' + code + '.'));
}

let lineIterator;
async function ask(question) {
  lineIterator = lineIterator || readline.createInterface({ input: process.stdin })[Symbol.asyncIterator]();
  process.stdout.write(question);
  const { value } = await lineIterator.next();     // works with piped input too
  if (value === undefined) process.stdout.write('\n');
  return (value || '').trim().toLowerCase();
}
async function confirm(question, def) {
  if (YES) return true;
  const a = await ask(`${question} [${def ? 'Y/n' : 'y/N'}] `);
  return a === '' ? def : a.startsWith('y');
}

main().then(() => process.exit(0), (e) => { console.error(e); process.exit(1); });
