using Toybox.Application;
using Toybox.Graphics;
using Toybox.Time;
using Toybox.WatchUi;

var view;

// data field values, corresponds to settingConfig list of
// propertyKey @Properties.dataField in resource/settings.xml
enum {
  activeMinutes,
  battery,
  date,
  distance,
  steps,
  stepGoal
}
var dataField = battery;

var showNotificationBar = true;

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
    
    showNotificationBar = app.getProperty("showNotificationBar");
    
    batteryWarn = app.getProperty("batteryWarn");
    batteryAlert = app.getProperty("batteryAlert");    
  }

  function onStop(state) {
    var app = Application.getApp();
    app.setProperty("dataField", dataField);
    app.setProperty("colorScheme", colorScheme);

	showNotificationBar = app.setProperty("showNotificationBar", showNotificationBar);
    
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
    
    showNotificationBar = app.getProperty("showNotificationBar");
    
    batteryWarn = app.getProperty("batteryWarn");
    batteryAlert = app.getProperty("batteryAlert"); 
    
    WatchUi.requestUpdate();
  }

}
