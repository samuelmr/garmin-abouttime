using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Math;
using Toybox.Application;
using Toybox.ActivityMonitor;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;

var locale = {};
var localeArrays = [];
var halfPast = true;
var updateCount = 0;
var fonts = new [6];
var lineHeight;
var iconHeight;

enum {
  tiny,
  small,
  medium,
  large,
  mega,
  icons
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
  }

  function onLayout(dc) {
    readLocale();

    fonts[tiny] = WatchUi.loadResource(@Rez.Fonts.id_font_tiny);
    fonts[small] = WatchUi.loadResource(@Rez.Fonts.id_font_small);
    fonts[medium] = WatchUi.loadResource(@Rez.Fonts.id_font_medium);
    fonts[large] = WatchUi.loadResource(@Rez.Fonts.id_font_large);
    fonts[mega] = WatchUi.loadResource(@Rez.Fonts.id_font_extralarge);
    fonts[icons] = WatchUi.loadResource(@Rez.Fonts.id_iconFont);

    // ugly hack: use system fonts for languages with unsupported glyphs
    if ((locale[:hours][1].find("一") != null) ||
        (locale[:hours][1].find("하나") != null)) {
      fonts[tiny] = Graphics.FONT_SMALL;
      fonts[small] = Graphics.FONT_MEDIUM;
      fonts[medium] = Graphics.FONT_SYSTEM_LARGE;
      fonts[large] = Graphics.FONT_SYSTEM_LARGE;
      fonts[mega] = fonts[large];
    }

    lineHeight = Graphics.getFontHeight(fonts[tiny])/1.7;
    iconHeight = Graphics.getFontHeight(fonts[icons]) + 4;

  }

  function onPartialUpdate(dc) {
		var clockTime = System.getClockTime();
		if (clockTime.sec == 30) {
			WatchUi.requestUpdate();
		}
	}

  function onUpdate(dc) {
    var width = dc.getWidth();
    var height = dc.getHeight();

    if (colorScheme == inverted) {
      bgColor = Graphics.COLOR_WHITE;
      textColor = Graphics.COLOR_BLACK;
      dataColor = Graphics.COLOR_DK_GRAY;
    }
    else {
      bgColor = Graphics.COLOR_BLACK;
      textColor = Graphics.COLOR_WHITE;
      dataColor = Graphics.COLOR_LT_GRAY;
    }

    dc.setColor(bgColor, textColor);
    dc.fillRectangle(0, 0, width, height);

    var timeSpace = drawTimeStrings(dc, System.getClockTime());

    if (height - lineHeight > timeSpace[:bottom]) {
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
      }

      if (dataString == null) {
        return;
      }

      if (dataString has :toString) {
        dataString = dataString.toString();
      }

      if (dataString instanceof Lang.String) {
        drawString(dc, width/2, height-lineHeight, fonts[tiny], dataColor, dataString);
      }
      else {
        System.println(dataString + " is not a string");
      }
    }

    if ((timeSpace[:top] > iconHeight) && showIcons) {
      drawIcons(dc, timeSpace[:top]);
    }
  }

  function drawIcons(dc, verticalSpace) {

    var settings = System.getDeviceSettings();
    var profile = UserProfile.getProfile();
    var stats = System.getSystemStats();
    var now = Time.now();
    var today = Time.today();

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
    if (now.greaterThan(today.add(profile.sleepTime)) && now.lessThan(today.add(profile.wakeTime))) {
      iconString += fontIcons[:sleep];
    }

    var textColor = Graphics.COLOR_WHITE;
    if (colorScheme == inverted) {
      textColor = Graphics.COLOR_BLACK;
    }
    var x = dc.getWidth()/2;
    var y = 4 + Graphics.getFontHeight(fonts[icons])/2;
    drawString(dc, x, y, fonts[icons], textColor, iconString);

  }

  function drawString(dc, x, y, font, color, string) {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(x, y, font, string, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
  }

  function drawTimeStrings(dc, time) {

    var timeSpace = {};

    var width = dc.getWidth();
    var height = dc.getHeight();

    var r = 0;

    var currentLocale = localize();
    var strings = prepareStrings(time, currentLocale);
    var top = strings[:top];
    var topFont = strings[:topFont];
    var middle = strings[:middle];
    var middleFont = strings[:middleFont];
    var bottom = strings[:bottom];
    var bottomFont = strings[:bottomFont];

    topFont = scaleFont(dc, topFont, top, :top);
    middleFont = scaleFont(dc, middleFont, middle, :middle);
    bottomFont = scaleFont(dc, bottomFont, bottom, :bottom);

    var topHeight = Graphics.getFontHeight(topFont)/1.25;
    var middleHeight = Graphics.getFontHeight(middleFont)/1.25;
    var bottomHeight = Graphics.getFontHeight(bottomFont)/1.25;
/*
    var topHeight = dc.getTextDimensions(top, topFont)[1]/1.2;
    var middleHeight = dc.getTextDimensions(middle, middleFont)[1]/1.2;
    var bottomHeight = dc.getTextDimensions(bottom, bottomFont)[1]/1.2;
*/
    var totalHeight = topHeight + middleHeight + bottomHeight;

    var x = width / 2;
    var topY = height / 2 - totalHeight / 2 + topHeight/2;
    var middleY = topY + topHeight / 2 + middleHeight / 2;
    var bottomY = middleY + middleHeight / 2 + bottomHeight / 2;
    var color = textColor;

    drawString(dc, x, topY, topFont, color, top);
    drawString(dc, x, middleY, middleFont, color, middle);
    drawString(dc, x, bottomY, bottomFont, color, bottom);

    timeSpace[:top] = topY - topHeight/2;
    timeSpace[:bottom] = bottomY + bottomHeight/2;
    return timeSpace;

  }

  function scaleFont(dc, font, string, position) {
    var width = dc.getWidth();
    var device = System.getDeviceSettings();
    var shape = device.screenShape;
    if ((shape == System.SCREEN_SHAPE_ROUND) && (position != :middle)) {
      width = 0.9 * width;
    }

    var strWidth = dc.getTextWidthInPixels(string, font);
    var fontIndex = 2; // default for Epix

    if (fonts has :indexOf) {
      fontIndex = fonts.indexOf(font);
    }

    if ((width > 180) && (string.length() <= 9)) {
      if (fontIndex < (fonts.size() - 1)) {
        fontIndex += 1;
        font = fonts[fontIndex];
        strWidth = dc.getTextWidthInPixels(string, font);
      }
    }
    while ((strWidth > width) && (fontIndex >= 0)) {
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

  function prepareStrings(time, currentLocale) {
    var top = "";
    var middle = "";
    var bottom = "";

    var fuzzyHour = time.hour;
    var fuzzyMinutes = ((time.min + 2) / 5) * 5;

    if (fuzzyMinutes > 55) {
      fuzzyMinutes = 0;
      fuzzyHour += 1;
      if (fuzzyHour > 23) {
        fuzzyHour = 0;
      }
    }
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
        if (! arr has :add) { // epix doesn't support array.add()
          return str.substring(0, splitIndex);
        }
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
