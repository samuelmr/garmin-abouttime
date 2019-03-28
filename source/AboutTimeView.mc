using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Math;

var locale = {};
var localeArrays = [];
var halfPast = true;
var updateCount = 0;
var smallFont;
var mediumFont;
var largeFont;

class AboutTimeView extends WatchUi.WatchFace {

  function initialize() {
    WatchFace.initialize();
    Math.srand(System.getTimer());
  }

  function onLayout(dc) {
    readLocale();

    smallFont = WatchUi.loadResource(Rez.Fonts.id_font_small);
    mediumFont = WatchUi.loadResource(Rez.Fonts.id_font_medium);
    largeFont = WatchUi.loadResource(Rez.Fonts.id_font_large);

  }

  function onUpdate(dc) {
    var width = dc.getWidth();
    var height = dc.getHeight();

    // updateCount += 1;
    // System.println("updating " + updateCount);

    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
    dc.fillRectangle(0, 0, width, height);

    var heightUsed = drawTimeStrings(dc, System.getClockTime());
    var lineHeight = Graphics.getFontHeight(Graphics.FONT_XTINY);

    if (height - lineHeight > heightUsed) {
      var dataString = (System.getSystemStats().battery + 0.5).toNumber().toString() + " %";
      drawString(dc, width/2, height-lineHeight, Graphics.FONT_XTINY, Graphics.COLOR_WHITE, dataString);
    }

  }

  function drawString( dc, x, y, font, color, string ) {
    dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    dc.drawText(x, y, font, string, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
  }

  function drawTimeStrings(dc, time) {

    var width = dc.getWidth();
    var height = dc.getHeight();

    var r = 0;

    var currentLocale = localize();
    var strings = prepareStrings(time, currentLocale);

    var topHeight = Graphics.getFontHeight(strings[:topFont])/1.4;
    var middleHeight = Graphics.getFontHeight(strings[:middleFont])/1.4;
    var bottomHeight = Graphics.getFontHeight(strings[:bottomFont])/1.4;

    var color = Graphics.COLOR_WHITE;
    var x = width / 2;
    var y = height * 2 / 5;

    drawString(dc, x, y - middleHeight/2 - topHeight/2, strings[:topFont], color, strings[:top]);
    drawString(dc, x, y, strings[:middleFont], color, strings[:middle]);
    drawString(dc, x, y + middleHeight/2 + bottomHeight/2, strings[:bottomFont], color, strings[:bottom]);

    return y + middleHeight/2 + bottomHeight/2 + bottomHeight;

  }

  function readLocale() {
    locale = {
      :little => WatchUi.loadResource(Rez.Strings.little),
      :almost => WatchUi.loadResource(Rez.Strings.almost),
      :quarter => WatchUi.loadResource(Rez.Strings.quarter),
      :ten => WatchUi.loadResource(Rez.Strings.ten),
      :twenty => WatchUi.loadResource(Rez.Strings.twenty),
      :to => WatchUi.loadResource(Rez.Strings.to),
      :past => WatchUi.loadResource(Rez.Strings.past),
      :half => WatchUi.loadResource(Rez.Strings.half),
      :hours => [
        "",
        WatchUi.loadResource(Rez.Strings.hours1),
        WatchUi.loadResource(Rez.Strings.hours2),
        WatchUi.loadResource(Rez.Strings.hours3),
        WatchUi.loadResource(Rez.Strings.hours4),
        WatchUi.loadResource(Rez.Strings.hours5),
        WatchUi.loadResource(Rez.Strings.hours6),
        WatchUi.loadResource(Rez.Strings.hours7),
        WatchUi.loadResource(Rez.Strings.hours8),
        WatchUi.loadResource(Rez.Strings.hours9),
        WatchUi.loadResource(Rez.Strings.hours10),
        WatchUi.loadResource(Rez.Strings.hours11)
      ],
      :noon => WatchUi.loadResource(Rez.Strings.noon),
      :midnight => WatchUi.loadResource(Rez.Strings.midnight),
      :halfpast => WatchUi.loadResource(Rez.Strings.halfpast)
    };

    if (locale[:halfpast].equals("false")) {
      halfPast = false;
    }

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
    var fuzzyHours = time.hour;
    var fuzzyMinutes = ((time.min + 2) / 5) * 5;

    if (fuzzyMinutes > 55) {
      fuzzyMinutes = 0;
      fuzzyHours += 1;
      if (fuzzyHours > 23) {
        fuzzyHours = 0;
      }
    }

    var top = "";
    var middle = "";
    var bottom = "";
    var topFont = mediumFont;
    var middleFont = smallFont;
    var bottomFont = largeFont;

    switch (fuzzyMinutes) {
      case 55:
        middleFont = mediumFont;
        middle += currentLocale[:almost];
        fuzzyHours = (fuzzyHours + 1) % 24;
        break;
      case 50:
        top += currentLocale[:ten];
        middle += currentLocale[:to];
        fuzzyHours = (fuzzyHours + 1) % 24;
        break;
      case 45:
        top += currentLocale[:quarter];
        middle += currentLocale[:to];
        fuzzyHours = (fuzzyHours + 1) % 24;
        break;
      case 40:
        top += currentLocale[:twenty];
        middle += currentLocale[:to];
        fuzzyHours = (fuzzyHours + 1) % 24;
        break;
      case 35:
        topFont = smallFont;
        middleFont = mediumFont;
        top += currentLocale[:little];
        middle += currentLocale[:past] + " " + currentLocale[:half];
        fuzzyHours = (fuzzyHours + (halfPast ? 0 : 1)) % 24;
        break;
      case 30:
        middle += currentLocale[:half];
        fuzzyHours = (fuzzyHours + (halfPast ? 0 : 1)) % 24;
        break;
      case 25:
        topFont = smallFont;
        middleFont = mediumFont;
        top += currentLocale[:almost];
        middle += currentLocale[:half];
        fuzzyHours = (fuzzyHours + (halfPast ? 0 : 1)) % 24;
        break;
      case 20:
        top += currentLocale[:twenty];
        middle += currentLocale[:past];
        break;
      case 15:
        top += currentLocale[:quarter];
        middle += currentLocale[:past];
        break;
      case 10:
        top += currentLocale[:ten];
        middle += currentLocale[:past];
        break;
      case 5:
        top += currentLocale[:little];
        middle += currentLocale[:past];
      break;
    }
    if (fuzzyHours == 0) {
      bottom += currentLocale[:midnight];
    } else if (fuzzyHours == 12) {
      bottom += currentLocale[:noon];
    } else {
      bottom += currentLocale[:hours][fuzzyHours % 12];
    }
    if (top.length() > 13) {
      topFont = smallFont;
    }
    if (middle.length() > 13) {
      middleFont = smallFont;
    }
    if (bottom.length() > 13) {
      bottomFont = smallFont;
    }
    if ((bottom.length() > 9) and (bottomFont == largeFont)) {
      bottomFont = mediumFont;
    }
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
  function onPowerBudgetExceeded(powerInfo) {
    System.println( "Average execution time: " + powerInfo.executionTimeAverage );
    System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
  }
}
