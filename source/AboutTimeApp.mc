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
  heartRate
}
var dataField = date;

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
    colorScheme = app.getProperty("colorScheme");

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
    app.setProperty("colorScheme", colorScheme);

    showIcons = app.setProperty("showIcons", showIcons);

    batteryWarn = app.setProperty("batteryWarn", batteryWarn);
    batteryAlert = app.setProperty("batteryAlert", batteryAlert);
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
    colorScheme = app.getProperty("colorScheme");

    showIcons = app.getProperty("showIcons");

    batteryWarn = app.getProperty("batteryWarn");
    batteryAlert = app.getProperty("batteryAlert");

    WatchUi.requestUpdate();
  }

}
