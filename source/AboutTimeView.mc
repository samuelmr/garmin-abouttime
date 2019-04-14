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

    // ugly hack: use system fonts for traditional Chinese
    if (locale[:hours][1].find("一") != null) {
      smallFont = Graphics.FONT_TINY;
      mediumFont = Graphics.FONT_MEDIUM;
      largeFont = Graphics.FONT_SYSTEM_LARGE;
    }

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

    var topHeight = Graphics.getFontHeight(strings[:topFont])/1.2;
    var middleHeight = Graphics.getFontHeight(strings[:middleFont])/1.2;
    var bottomHeight = Graphics.getFontHeight(strings[:bottomFont])/1.2;

    var color = Graphics.COLOR_WHITE;
    var x = width / 2;
    var y = height / 2 - Graphics.getFontHeight(Graphics.FONT_XTINY) / 2;

    drawString(dc, x, y - middleHeight/2 - topHeight/2, strings[:topFont], color, strings[:top]);
    drawString(dc, x, y, strings[:middleFont], color, strings[:middle]);
    drawString(dc, x, y + middleHeight/2 + bottomHeight/2, strings[:bottomFont], color, strings[:bottom]);

    return y + middleHeight/2 + bottomHeight/2 + bottomHeight;

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
    var topFont = mediumFont;
    var middleFont = smallFont;
    var bottomFont = largeFont;

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
    } else if (fuzzyHour == 12) {
      fuzzyHour = currentLocale[:noon];
    } else {
      fuzzyHour = currentLocale[:hours][fuzzyHour % 12];
    }

    if (nextHour == 24) {
      nextHour = currentLocale[:midnight];
    } else if (nextHour == 12) {
      nextHour = currentLocale[:noon];
    } else {
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

    if (lines[0].find("$") != null) {
      topFont = largeFont;
      bottomFont = mediumFont;
    }
    if (lines[1].find("$") != null) {
      middleFont = largeFont;
      bottomFont = mediumFont;
    }

    var params = [fuzzyHour, nextHour];

    top = Lang.format(lines[0], params);
    middle = Lang.format(lines[1], params);
    bottom = Lang.format(lines[2], params);

    if (top.length() > 13) {
      topFont = smallFont;
    }
    if (middle.length() > 13) {
      middleFont = smallFont;
    }
    if (bottom.length() > 13) {
      bottomFont = smallFont;
    }
    if ((middle.length() >= 9) and (middleFont == largeFont)) {
      middleFont = mediumFont;
    }
    if ((bottom.length() >= 9) and (bottomFont == largeFont)) {
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
  function onPowerBudgetExceeded(powerInfo) {
    System.println( "Average execution time: " + powerInfo.executionTimeAverage );
    System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
  }
}
