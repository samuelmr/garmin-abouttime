using Toybox.Application;
using Toybox.Graphics;
using Toybox.Time;
using Toybox.WatchUi;

var view;

var dataField;
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

var bgColor = Graphics.COLOR_BLACK;
var textColor = Graphics.COLOR_WHITE;
var dataColor = Graphics.COLOR_LT_GRAY;
enum {
  normal,   // white on black
  inverted  // black on white
}
var colorScheme = inverted;

class AboutTime extends Application.AppBase {

  function initialize() {
    AppBase.initialize();
  }

  function onStart(state) {
    dataField = steps;
    var app = Application.getApp();
    var storedDataField = app.getProperty("dataField");
    if (storedDataField != null) {
      dataField = storedDataField;
    }
    colorScheme = app.getProperty("colorScheme");
    if (colorScheme == inverted) {
      bgColor = Graphics.COLOR_WHITE;
      textColor = Graphics.COLOR_BLACK;
      dataColor = Graphics.COLOR_DK_GRAY;
    }
  }

  function onStop(state) {
    var app = Application.getApp();
    app.setProperty("dataField", dataField);
    app.setProperty("colorScheme", colorScheme);
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
      WatchUi.requestUpdate();
  }




}
