using Toybox.Application;
using Toybox.Graphics;
using Toybox.Time;
using Toybox.WatchUi;

var view;

// data field values, corresponds to settingConfig list of
// propertyKey @Properties.dataField in resources/settings.xml
enum {
  hide,
  battery,
  date,
  distance,
  steps,
  stepGoal,
  exactTime,
  activeMinutes,
  heartRate,
  timeNoSeconds
}
var dataField = date;

// date format values, corresponds to settingConfig list of
// propertyKey @Properties.dateFormat in resources/settings.xml
enum {
  dayMonth,      // 31.12.
  monthDaySlash, // 12/31
  dayMonthSlash  // 31/12
}
var dateFormat = dayMonth;

var smallerFont = false;

var showIcons = true;

var batteryWarn = 30;
var batteryAlert = 10;

enum {
  normal,   // white on black
  inverted  // black on white
}
var colorScheme = normal;

class AboutTime extends Application.AppBase {

  function initialize() {
    AppBase.initialize();
  }

  function onStart(state) {
    var app = Application.getApp();
    var storedDataField = app.getProperty("dataField");
    if (storedDataField != null) {
      dataField = storedDataField;
    }
    var storedDateFormat = app.getProperty("dateFormat");
    if (storedDateFormat != null) {
      dateFormat = storedDateFormat;
    }
    colorScheme = app.getProperty("colorScheme");

    smallerFont = app.getProperty("smallerFont");
    if (smallerFont != true) {
      smallerFont = false;
    }

    showIcons = app.getProperty("showIcons");
    if (showIcons != false) {
      showIcons = true;
    }

    var storedBatteryWarn = app.getProperty("batteryWarn");
    if (storedBatteryWarn != null) {
      batteryWarn = storedBatteryWarn;
    }
    var storedBatteryAlert = app.getProperty("batteryAlert");
    if (storedBatteryAlert != null) {
      batteryAlert = storedBatteryAlert;
    }

  }

  function onStop(state) {
    var app = Application.getApp();
    app.setProperty("dataField", dataField);
    app.setProperty("dateFormat", dateFormat);
    app.setProperty("colorScheme", colorScheme);

    app.setProperty("smallerFont", smallerFont);
    app.setProperty("showIcons", showIcons);

    app.setProperty("batteryWarn", batteryWarn);
    app.setProperty("batteryAlert", batteryAlert);
  }

  function getInitialView() {
    view = new AboutTimeView();
    if( WatchUi has :WatchFaceDelegate ) {
      return [view, new AboutTimeDelegate()];
    } else {
      return [view];
    }
  }

  function onSettingsChanged() {
    var app = Application.getApp();

    dataField = app.getProperty("dataField");
    var newDateFormat = app.getProperty("dateFormat");
    if (newDateFormat != null) {
      dateFormat = newDateFormat;
    }
    colorScheme = app.getProperty("colorScheme");

    smallerFont = app.getProperty("smallerFont");
    showIcons = app.getProperty("showIcons");

    batteryWarn = app.getProperty("batteryWarn");
    batteryAlert = app.getProperty("batteryAlert");

    WatchUi.requestUpdate();
  }

}
