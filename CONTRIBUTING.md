# Creating a new translation

## The easiest method

1. Go to https://docs.google.com/spreadsheets/d/1rqoHvd_8lOEooDplv6kUgsBH1nO9YNz6JuFV_6bVoxA/
2. Duplicate any sheet
3. Rename the duplicated sheet to the language of your translation
4. Drag the sheet to the correct alphabetical order
5. Translate the strings in rows 1 to 48 to your language
6. Change the URL in the cell C4 to the URL of your sheet

I will get a notification that the spreadsheet is changed. I will take care of the rest.

## The hard way

If you find the following instructions difficult, use the easy method.

You should have the latest version of Garmin's [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) installed.

1. Clone this repository
2. Decide a three letter acronym for your language
3. Create the structure 
4. Edit `manifest-$LNG.xml` and set the `id` attribute of the `iq:application` element to a new UUID. (You can get one from [uuidgenerator.net](https://www.uuidgenerator.net/version4))
5. Translate strings in `resources-$LNG/strings.xml` (and `resources-$LNG/settingstrings.xml`)
6. Compile your translation and make sure there are no errors
7. Run the translation in the simulator
8. Run Time Simulation (in the maximum speed factor) and let it run 24 hours
9. Commit your changes and make a pull request

### Example shell commands

Instructions for using git and creating pull requests are omitted on purpose.
Please only use this method if you have experience in contributing to source code.
```sh
# step 2, using 'lng' as the language identifier
LNG=lng

# step 3
cd garmin-abouttime
cp -pR resources-eng resources-$LNG
cp monkey-eng.jungle monkey-$LNG.jungle
cat monkey-eng.jungle | sed -e "s/-eng/-$LNG/" > monkey-$LNG.jungle
cp manifest-eng.xml manifest-$LNG.xml

# step 6
./filter.sh
monkeyc -f monkey-$LNG.jungle -d fenix5plus -y path_to_your_keyfile -o AboutTime-$LNG.prg

# step 7
connectiq
monkeydo AboutTime-$LNG.prg fenix5plus
```