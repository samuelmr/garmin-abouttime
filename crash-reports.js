// const { exec } = require('node:child_process')
const util = require('util');
const exec = util.promisify(require('child_process').exec);

const allTranslations = require('./translations.json')
const key = process.env.CIQ_KEYFILE

let translations = Object.entries(allTranslations)
if (process.argv.length > 2) {
  const tk = process.argv.slice(2)
  translations = translations.filter((e) => tk.includes(e[1]))
}

const getReports = async (translations) => {
  const results = {}
  for (e of translations) {
    cmd = `era -a ${e[0]} -k ${key}`
    const { stdout, stderr } = await exec(cmd)
    if (stderr) {
      console.warn(cmd, stderr)
    }
    const obj = JSON.parse(stdout)
    results[e[1]] = obj
  }
  console.log(JSON.stringify(results, null, 1))
}

getReports(translations)

