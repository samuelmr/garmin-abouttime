using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Math;
using Toybox.Application;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;

var locale = {};
var localeArrays = [];
var halfPast = true;
var updateCount = 0;
var fonts = new [7];
var lineHeight, iconHeight;
var prevTime, prevIcons;
var width, height, shape, device;
var canBurnIn = false;
var upTop = true;
var inLowPower =false;
// vertical compression of lines (decrease line spacing)
var linePack = 1.5; 

enum {
  tiny,
  small,
  medium,
  large,
  mega,
  icons,
  icons_large
}

var bgColor = Graphics.COLOR_BLACK;
var textColor = Graphics.COLOR_WHITE;
var dataColor = Graphics.COLOR_LT_GRAY;

var fontIcons = {
  :alarm => "0",
  :batteryAlert => "1",
  :batteryCharging => "2",
  :batteryWarning => "3",
  :disconnected => "5",
  :sleep  => "6",
  :notification => "7"
};

class AboutTimeView extends WatchUi.WatchFace {
  function initialize() {
    WatchFace.initialize();
    Math.srand(System.getTimer());
    //check if burn in protection needed
    var sysSettings = System.getDeviceSettings();
    //first check if the setting is availe on the current device
    if(sysSettings has :requiresBurnInProtection) {
      //get the state of the setting
      canBurnIn = sysSettings.requiresBurnInProtection;
    }
  }

  function onLayout(dc) {

    readLocale();
    device = System.getDeviceSettings();
    height = dc.getHeight();
    width = dc.getWidth();
    shape = device.screenShape;
    fonts[tiny] = WatchUi.loadResource(@Rez.Fonts.id_font_tiny);
    fonts[small] = WatchUi.loadResource(@Rez.Fonts.id_font_small);
    fonts[medium] = WatchUi.loadResource(@Rez.Fonts.id_font_medium);
    fonts[large] = WatchUi.loadResource(@Rez.Fonts.id_font_large);
    if (smallerFont == false) {
      fonts[mega] = WatchUi.loadResource(@Rez.Fonts.id_font_extralarge);
    }

    // ugly hack: use system fonts for languages with unsupported glyphs
    if ((locale[:hours][1].find("一") != null) ||
        (locale[:hours][1].find("하나") != null)) {
      fonts[tiny] = Graphics.FONT_SMALL;
      fonts[small] = Graphics.FONT_MEDIUM;
      fonts[medium] = Graphics.FONT_SYSTEM_LARGE;
      fonts[large] = Graphics.FONT_SYSTEM_LARGE;
      // fonts[mega] = fonts[large];
      // no vertical compression for system fonts
      linePack = 1;
    }

    if (smallerFont == false) {
      fonts[icons] = WatchUi.loadResource(@Rez.Fonts.id_iconFontLarge);
    }
    else {
      fonts[icons] = WatchUi.loadResource(@Rez.Fonts.id_iconFont);
    }
    lineHeight = Graphics.getFontHeight(fonts[tiny]) / 2;
    iconHeight = Graphics.getFontHeight(fonts[icons]);
  }

  function onPartialUpdate(dc) {
    var clockTime = System.getClockTime();
    if (dataField == exactTime) {
      WatchUi.requestUpdate();
    }
    else if (clockTime.sec == 30) {
      WatchUi.requestUpdate();
    }
  }

  function onExitSleep() {
    inLowPower = false;
    WatchUi.requestUpdate();
  }

  function onEnterSleep() {
    inLowPower = true;
    WatchUi.requestUpdate();
  }

  function onUpdate(dc) {

    var time = System.getClockTime();
    var fuzzyHour = time.hour;
    var fuzzyMinutes = ((time.min + 2) / 5) * 5;
    if (fuzzyMinutes > 55) {
      fuzzyMinutes = 0;
      fuzzyHour += 1;
      if (fuzzyHour > 23) {
        fuzzyHour = 0;
      }
    }

    var iconString = getIconString();
    
/*
 * It seems we need to redraw the screen anyway. Just returning from
 * onUpdate() may cause the screen to appear blank on real devices
 * (although it works fine in the simulator)
 *
 * See https://github.com/samuelmr/garmin-abouttime/issues/13
 *
    var thisTime = fuzzyHour.format("%d") + ":" + fuzzyMinutes.format("%02d");
    if (thisTime.equals(prevTime) && iconString.equals(prevIcons)) {
      // time and status haven't really changed, no need to update
      // System.println(thisTime + " – " + iconString);
      return;
    }
    prevTime = thisTime;
    prevIcons = iconString;
    // var thisTime = fuzzyHour.format("%d") + ":" + fuzzyMinutes.format("%02d");
    // System.println(thisTime + " – " + iconString);
*/

    if (colorScheme == inverted) {
      bgColor = Graphics.COLOR_WHITE;
      textColor = Graphics.COLOR_BLACK;
      dataColor = Graphics.COLOR_DK_GRAY;
    }

    dc.setColor(bgColor, bgColor);
    dc.clear();
    var timeSpace = drawTimeStrings(dc, fuzzyHour, fuzzyMinutes);

    if ((dataField != hide) && (height - lineHeight > timeSpace[:bottom])) {
      var activityInfo;
      var dataString = (System.getSystemStats().battery + 0.5).format("%d") + " %";
      switch(dataField) {
        case activeMinutes:
          activityInfo = ActivityMonitor.getInfo();
          dataString = activityInfo.activeMinutesDay;
          break;
        case date:
          var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
          dataString = Lang.format("$1$.$2$.", [today.day, today.month]);
          break;
        case distance:
          activityInfo = ActivityMonitor.getInfo();
          var centimeters = activityInfo.distance;
          if (centimeters == null) {
            dataString = "0 m";
          }
          else if (centimeters > 100000) {
            dataString = (centimeters / 100000).format("%.1f") + " km";
          }
          else {
            dataString = (centimeters / 100).format("%d") + " m";
          }
          break;
        case steps:
          activityInfo = ActivityMonitor.getInfo();
          dataString = activityInfo.steps;
          break;
        case stepGoal:
          activityInfo = ActivityMonitor.getInfo();
          dataString = activityInfo.stepGoal;
          break;
        case exactTime:
          dataString = Lang.format("$1$:$2$:$3$", [time.hour.format("%d"), time.min.format("%02d"), time.sec.format("%02d")]);
          break;
        case heartRate:
          if (ActivityMonitor has :getHeartRateHistory) {
            dataString = Activity.getActivityInfo().currentHeartRate;
            if(dataString == null) {
              var hrHistory = ActivityMonitor.getHeartRateHistory(1, true);
              var hrSample = hrHistory.next();
              if(hrSample != null && hrSample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE){
                dataString = hrSample.heartRate;
              }
            }
          }
          break;
      }
      if (dataString == null) {
        return;
      }
      if (dataString has :toString) {
        dataString = dataString.toString();
      }

      if (dataString instanceof Lang.String) {
        drawString(dc, width/2, height-lineHeight, fonts[tiny], dataColor, Graphics.TEXT_JUSTIFY_CENTER, dataString);
      }
      else {
        // System.println(dataString + " is not a string");
      }
    }

    var x = width/2;
    if (WatchUi has :getSubscreen && WatchUi.getSubscreen() != null) {
      // stupid hard coded value just for descentg1 and instinct2
      x -= 20;
    }
    if ((timeSpace[:top] >= iconHeight) && showIcons) {
      drawString(dc, x, iconHeight, fonts[icons], textColor, Graphics.TEXT_JUSTIFY_CENTER, iconString);
    }

  }

  function getIconString() {

    var settings = System.getDeviceSettings();
    var profile = UserProfile.getProfile();
    var stats = System.getSystemStats();

    var now = Time.now();
    var today = Time.today();
    var isSleepTime = now.greaterThan(today.add(profile.sleepTime)) &&
                      now.lessThan(today.add(profile.wakeTime));

    var doNotDisturb = false;
    if (settings has :doNotDisturb) {
      doNotDisturb = settings.doNotDisturb;
    }

    var iconString = "";
    if (!settings.phoneConnected) {
      iconString += fontIcons[:disconnected];
    }
    if (settings.alarmCount > 0) {
      iconString += fontIcons[:alarm];
    }
    if (settings.notificationCount > 0) {
      iconString += fontIcons[:notification];
    }
    if (stats has :charging && stats.charging) {
      iconString += fontIcons[:batteryCharging];
    }
    else if ((stats.battery + 0.5).toNumber() < batteryAlert) {
      iconString += fontIcons[:batteryAlert];
    }
    else if ((stats.battery + 0.5).toNumber() < batteryWarn) {
      iconString += fontIcons[:batteryWarning];
    }
    if (isSleepTime || doNotDisturb) {
      iconString += fontIcons[:sleep];
    }
    return iconString;

  }

  function drawString(dc, x, y, font, color, alignment, string) {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(x, y, font, string, alignment | Graphics.TEXT_JUSTIFY_VCENTER);
  }

  function drawTimeStrings(dc, fuzzyHour, fuzzyMinutes) {

    var timeSpace = {};

    var currentLocale = localize();
    var strings = prepareStrings(fuzzyHour, fuzzyMinutes, currentLocale);
    var top = strings[:top];
    var topFont = strings[:topFont];
    var middle = strings[:middle];
    var middleFont = strings[:middleFont];
    var bottom = strings[:bottom];
    var bottomFont = strings[:bottomFont];

    // System.println(strings[:top] + strings[:middle] + strings[:bottom]);

    topFont = scaleFont(dc, topFont, top, :top);
    middleFont = scaleFont(dc, middleFont, middle, :middle);
    bottomFont = scaleFont(dc, bottomFont, bottom, :bottom);

    var topHeight = Graphics.getFontHeight(topFont) / linePack;
    var middleHeight = Graphics.getFontHeight(middleFont) / linePack;
    var bottomHeight = Graphics.getFontHeight(bottomFont) / linePack;
    var totalHeight = topHeight + middleHeight + bottomHeight;

    var x = width / 2;
    var topY = height / 2 - totalHeight / 2 + topHeight / 2;
    if (WatchUi has :getSubscreen && WatchUi.getSubscreen() != null) {
      // stupid hard coded value just for descentg1 and instinct2
      topY += 20;
    }
    var middleY = topY + topHeight / 2 + middleHeight / 2;
    var bottomY = middleY + middleHeight / 2 + bottomHeight / 2;    
    if (inLowPower && canBurnIn) {
      // move by 1 pixel to prevent burn-in
      x += upTop ? 1 : 0;
      topY += upTop ? 1 : 0;
      middleY += upTop ? 1 : 0;
      bottomY += upTop ? 1 : 0;
      upTop = !upTop;
    }

    var color = textColor;

    drawString(dc, x, topY, topFont, color, Graphics.TEXT_JUSTIFY_CENTER, top);
    drawString(dc, x, middleY, middleFont, color, Graphics.TEXT_JUSTIFY_CENTER, middle);
    drawString(dc, x, bottomY, bottomFont, color, Graphics.TEXT_JUSTIFY_CENTER, bottom);

    timeSpace[:top] = topY - topHeight/2;
    timeSpace[:bottom] = bottomY + bottomHeight/2;

    return timeSpace;

  }

  function scaleFont(dc, font, string, position) {

    var lineWidth = width;
    if ((shape == System.SCREEN_SHAPE_ROUND) && (position != :middle)) {
      lineWidth = 0.9 * width;
    }
    if ((position == :top) && (WatchUi has :getSubscreen) && (WatchUi.getSubscreen() == null)) {
      lineWidth = 0.7 * width;
    }

    var strWidth = dc.getTextWidthInPixels(string, font);
    var fontIndex = medium;

    if (fonts has :indexOf) {
      fontIndex = fonts.indexOf(font);
    }

    if ((smallerFont == false) && (lineWidth > 180) && (string.length() <= 9)) {
      if (fontIndex < (fonts.size() - 1)) {
        fontIndex += 1;
        font = fonts[fontIndex];
        try {
          // this line was causing "Unhandled Exception" in some cases,
          // trying to catch errors
          strWidth = dc.getTextWidthInPixels(string, font);
        }
        catch (e instanceof Toybox.Lang.Exception) {
          System.println("Error when trying to set font to " + fontIndex.format("%d") + "/" + fonts.size().format("%d"));
          System.println(e.getErrorMessage());
        }
     }
    }
    while ((strWidth > lineWidth) && (fontIndex > 0)) {
      fontIndex -= 1;
      font = fonts[fontIndex];
      strWidth = dc.getTextWidthInPixels(string, font);
    }
    return font;

  }

  function readLocale() {
    locale = {
      "min0" => WatchUi.loadResource(Rez.Strings.min0),
      "min5" => WatchUi.loadResource(Rez.Strings.min5),
      "min10" => WatchUi.loadResource(Rez.Strings.min10),
      "min15" => WatchUi.loadResource(Rez.Strings.min15),
      "min20" => WatchUi.loadResource(Rez.Strings.min20),
      "min25" => WatchUi.loadResource(Rez.Strings.min25),
      "min30" => WatchUi.loadResource(Rez.Strings.min30),
      "min35" => WatchUi.loadResource(Rez.Strings.min35),
      "min40" => WatchUi.loadResource(Rez.Strings.min40),
      "min45" => WatchUi.loadResource(Rez.Strings.min45),
      "min50" => WatchUi.loadResource(Rez.Strings.min50),
      "min55" => WatchUi.loadResource(Rez.Strings.min55),
      :hours => [
        "",
        WatchUi.loadResource(Rez.Strings.hour1),
        WatchUi.loadResource(Rez.Strings.hour2),
        WatchUi.loadResource(Rez.Strings.hour3),
        WatchUi.loadResource(Rez.Strings.hour4),
        WatchUi.loadResource(Rez.Strings.hour5),
        WatchUi.loadResource(Rez.Strings.hour6),
        WatchUi.loadResource(Rez.Strings.hour7),
        WatchUi.loadResource(Rez.Strings.hour8),
        WatchUi.loadResource(Rez.Strings.hour9),
        WatchUi.loadResource(Rez.Strings.hour10),
        WatchUi.loadResource(Rez.Strings.hour11)
      ],
      :noon => WatchUi.loadResource(Rez.Strings.noon),
      :midnight => WatchUi.loadResource(Rez.Strings.midnight),
    };
    var keys = locale.keys();
    for (var i=0; i<keys.size(); i++) {
      var key = keys[i];
      locale[key] = strToArray(locale[key]);
      if (key != :hours && locale[key] instanceof Toybox.Lang.Array) {
        localeArrays.add({:name => key, :size => locale[key].size()});
      }
    }
    for (var i=0; i<locale[:hours].size(); i++) {
      locale[:hours][i] = strToArray(locale[:hours][i]);
      if (locale[:hours][i] instanceof Toybox.Lang.Array) {
        localeArrays.add({:name => i, :size => locale[:hours][i].size()});
      }
    }
  }

  function localize() {
    var currentLocale = cloneDictionary(locale);
    var i;
    for (i=0; i<localeArrays.size(); i++) {
      var it = localeArrays[i];
      var r = Math.rand() % it[:size];
      var key = it[:name];
      if (key instanceof Toybox.Lang.Number) {
        currentLocale[:hours][key] = locale[:hours][key][r];
      }
      else {
        currentLocale[key] = locale[key][r];
      }
    }
    return currentLocale;
  }

  function prepareStrings(fuzzyHour, fuzzyMinutes, currentLocale) {
    var top = "";
    var middle = "";
    var bottom = "";

    var nextHour = fuzzyHour + 1;

    if (fuzzyHour == 0) {
      fuzzyHour = currentLocale[:midnight];
    }
    else if (fuzzyHour == 12) {
      fuzzyHour = currentLocale[:noon];
    }
    else {
      fuzzyHour = currentLocale[:hours][fuzzyHour % 12];
    }

    if (nextHour == 24) {
      nextHour = currentLocale[:midnight];
    }
    else if (nextHour == 12) {
      nextHour = currentLocale[:noon];
    }
    else {
      nextHour = currentLocale[:hours][nextHour % 12];
    }

    var lineString = locale["min" + fuzzyMinutes];
    var lines = new [3];
    var firstIndex = lineString.find("	");
    if (firstIndex == null) {
      lines[0] = "";
      lines[1] = lineString;
      lines[2] = "";
    }
    else {
      lines[0] = "";
      lines[1] = lineString.substring(0, firstIndex);
      lines[2] = lineString.substring(firstIndex + 1, lineString.length());
      var secondIndex = lines[2].find("	");
      if (secondIndex != null) {
        lines[0] = lines[1];
        lines[1] = lines[2].substring(0, secondIndex);
        lines[2] = lines[2].substring(secondIndex + 1, lines[2].length());
      }
    }

    var topFont = fonts[small];
    var middleFont = fonts[medium];
    var bottomFont = fonts[large];

    if (lines[0].find("$") != null) {
      topFont = fonts[large];
      middleFont = fonts[small];
      bottomFont = fonts[medium];
    }
    else if ((lines[1].find("$") != null) && (lines[2].length() > 0)) {
      topFont = fonts[small];
      middleFont = fonts[large];
      bottomFont = fonts[medium];
    }
    else if (lines[1].find("$") != null) {
      topFont = fonts[medium];
      middleFont = fonts[large];
      bottomFont = fonts[tiny];
    }

    if (lines[0].length() == 0) {
      topFont = fonts[tiny];
    }

    if (lines[2].length() == 0) {
      bottomFont = fonts[tiny];
    }

    var params = [fuzzyHour, nextHour];

    top = Lang.format(lines[0], params);
    middle = Lang.format(lines[1], params);
    bottom = Lang.format(lines[2], params);

    return {
      :bottom => bottom,
      :bottomFont => bottomFont,
      :middle => middle,
      :middleFont => middleFont,
      :top => top,
      :topFont => topFont
    };
  }

  function strToArray(str) {
    if (str instanceof Toybox.Lang.String != true) {
      return str;
    }

    if (str.find("|")) {
      var arr = [];
      while (str.find("|")) {
        var splitIndex = str.find("|");
        // if (! arr has :add) { // epix doesn't support array.add()
        //   return str.substring(0, splitIndex);
        // }
        arr.add(str.substring(0, splitIndex));
        str = str.substring(splitIndex+1, str.length());
      }
      arr.add(str);
     return arr;
    }
    return str;
  }

  function cloneDictionary(source) {
    var target = {};
    var keys = source.keys();
    for (var i=0; i<keys.size(); i++) {
      if (source[keys[i]] instanceof Toybox.Lang.Array) {
        target[keys[i]] = cloneArray(source[keys[i]]);
      }
      else {
        target[keys[i]] = source[keys[i]];
      }
    }
    return target;
  }

  function cloneArray(source) {
    var target = new [source.size()];
    for (var i=0; i<source.size(); i++) {
      target[i] = source[i];
    }
    return target;
  }

}


class AboutTimeDelegate extends WatchUi.WatchFaceDelegate {

  function initialize() {
    WatchFaceDelegate.initialize();
  }
  function onPowerBudgetExceeded(powerInfo) {
    System.println( "Average execution time: " + powerInfo.executionTimeAverage );
    System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
  }
}
