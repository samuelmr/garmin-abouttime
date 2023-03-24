const puppeteer = require('puppeteer')
const config = require('./config.js')
const allTranslations = require('./translations.json')

const PAGE_TIMEOUT_S = 120
const HEADLESS = false

let translations = allTranslations
if (process.argv.length > 2) {
  const tk = process.argv.slice(2)
  translations = Object.fromEntries(Object.entries(allTranslations).filter((e) => tk.includes(e[1])))
}

const loginPage = 'https://apps.garmin.com/login';

(async () => {
  const browser = await puppeteer.launch({headless: HEADLESS})
  const page = await browser.newPage()
  page.setDefaultNavigationTimeout(PAGE_TIMEOUT_S * 1000)
  await page.goto(loginPage, {waitUntil: 'networkidle2'})

  await new Promise(r => setTimeout(r, 2 * 1000))
  const consentHandle = await page.$('#truste-consent-button')
  if (consentHandle) {
    await page.click('#truste-consent-button')
    await new Promise(r => setTimeout(r, 4 * 1000))
  }

  const elementHandle = await page.$('#gauth-widget-frame-gauth-widget')
  if (elementHandle) { // else assume we're authenticated
    const frame = await elementHandle.contentFrame()
    await frame.type('#username', config.username)
    await frame.type('#password', config.password)
    await frame.click('#login-btn-signin')
    await page.waitForNavigation()
  }

  let counter = 0
  for (uuid in translations) {
    try {
      const url = `https://apps.garmin.com/en-US/developer/${config.dev}/apps/${uuid}/update`
      await page.goto(url, {waitUntil: 'networkidle2'})

      const [versionElement] = await page.$x('//span[contains(text(), "Latest app version: ")]')
      const versionText = await page.evaluate(el => el.textContent, versionElement);
      if (versionText) {
        const match = versionText.match(/: ([\d\.]+)/)
        if (match[1] == config.version) {
          console.log(`Skipping ${translations[uuid]} ${versionText}`)
          continue;
        }
      }
      const input = await page.$('input[name=file]')
      await input.uploadFile(`./releases/AboutTime-${translations[uuid]}.iq`)
      await new Promise(r => setTimeout(r, 1 * 1000))
      await page.type('#app-version', config.version)
      await page.click('button[name="submit"]')
      await page.waitForNavigation();

      const successtHandle = await page.$('.text-success')
      if (successtHandle) {
        console.log(`Published version ${config.version} of ${translations[uuid]}`)
        ++counter
      }
      else {
        console.warn(`Error publishing v. ${config.version} of ${translations[uuid]}`)
        const alertHandle = await page.$('.alert-danger')
        if (alertHandle) {
          let value = await page.evaluate(el => el.textContent, alertHandle)
          console.log(value)
        }
      }
    }
    catch(e) {
      console.error(`Error publishing v. ${config.version} of ${translations[uuid]}`)
      throw new Error(e)
    }
  }
  console.log(`Published ${counter} translation${counter != 1 ? 's' : ''}.`)
  await browser.close();
})()

