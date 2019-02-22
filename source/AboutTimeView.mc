//
// Copyright 2016-2017 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Graphics;
using Toybox.System;
using Toybox.WatchUi;
// using Toybox.Application;

var locale = {};
var halfPast = true;

// This implements an AboutTime watch face
// Original design by Austen Harbour
class AboutTimeView extends WatchUi.WatchFace
{
    var font;
    var isAwake;

    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
    }

    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // locale = WatchUi.loadResource(Rez.JsonData.stringsJSON);
        locale = {
            "little" => [
                WatchUi.loadResource(Rez.Strings.little1),
                WatchUi.loadResource(Rez.Strings.little2)
            ],
            "almost" => [
                WatchUi.loadResource(Rez.Strings.almost1),
                WatchUi.loadResource(Rez.Strings.almost2)
            ],
            "quarter" => WatchUi.loadResource(Rez.Strings.quarter),
            "ten" => WatchUi.loadResource(Rez.Strings.ten),
            "twenty" => WatchUi.loadResource(Rez.Strings.twenty),
            "to" => WatchUi.loadResource(Rez.Strings.to),
            "past" => WatchUi.loadResource(Rez.Strings.past),
            "half" => WatchUi.loadResource(Rez.Strings.half),
            "hours" => [
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
            "noon" => WatchUi.loadResource(Rez.Strings.noon),
            "midnight" => WatchUi.loadResource(Rez.Strings.midnight),
            "halfpast" => WatchUi.loadResource(Rez.Strings.halfpast)
        };

        if (locale["halfpast"].equals("false")) {
            halfPast = false;
        }
    }

    // Handle the update event
    function onUpdate(dc) {
        var width;
        var height;
        var screenWidth = dc.getWidth();
        var clockTime = System.getClockTime();
        var minuteHandAngle;
        var hourHandAngle;
        var secondHand;

        width = dc.getWidth();
        height = dc.getHeight();

        // Fill the entire background with Black.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Output the offscreen buffers to the main display if required.
        drawTimeStrings(dc);

        // Draw the battery percentage directly to the main screen.
        var dataString = (System.getSystemStats().battery + 0.5).toNumber().toString() + "%";

        var lineHeight = Graphics.getFontHeight(Graphics.FONT_LARGE);
        drawString(dc, width/2, height-lineHeight, Graphics.FONT_TINY, Graphics.COLOR_WHITE, dataString);

    }

    // Draw the date string into the provided buffer at the specified location
    function drawString( dc, x, y, font, color, string ) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, string, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawTimeStrings(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        var clockTime = System.getClockTime();

        var fuzzyHours = clockTime.hour;
        var fuzzyMinutes = ((clockTime.min + 2) / 5) * 5;

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
        var topFont = Graphics.FONT_MEDIUM;
        var middleFont = Graphics.FONT_SMALL;
        var bottomFont = Graphics.FONT_LARGE;

        var fuzzyIndex = 0;
        if (fuzzyHours % 2) {
          fuzzyIndex = 1;
        }

        if (fuzzyMinutes != 0 && (fuzzyMinutes >= 10 || fuzzyMinutes == 5 || fuzzyHours == 0 || fuzzyHours == 12)) {
          if (fuzzyMinutes == 55) {
            middleFont = Graphics.FONT_MEDIUM;
            middle += locale["almost"][fuzzyIndex];
            fuzzyHours = (fuzzyHours + 1) % 24;
          } else if (fuzzyMinutes == 50) {
            top += locale["ten"];
            middle += locale["to"];
            fuzzyHours = (fuzzyHours + 1) % 24;
          } else if (fuzzyMinutes == 45) {
            top += locale["quarter"];
            middle += locale["to"];
            fuzzyHours = (fuzzyHours + 1) % 24;
          } else if (fuzzyMinutes == 40) {
            top += locale["twenty"];
            middle += locale["to"];
            fuzzyHours = (fuzzyHours + 1) % 24;
          } else if (fuzzyMinutes == 35) {
            topFont = Graphics.FONT_SMALL;
            middleFont = Graphics.FONT_MEDIUM;
            top += locale["little"][fuzzyIndex];
            middle += locale["past"] + " " + locale["half"];
            fuzzyHours = (fuzzyHours + (halfPast ? 0 : 1)) % 24;
          } else if (fuzzyMinutes == 30) {
            middle += locale["half"];
            fuzzyHours = (fuzzyHours + (halfPast ? 0 : 1)) % 24;
          } else if (fuzzyMinutes == 25) {
            topFont = Graphics.FONT_SMALL;
            middleFont = Graphics.FONT_MEDIUM;
            top += locale["almost"][fuzzyIndex];
            middle += locale["half"];
            fuzzyHours = (fuzzyHours + (halfPast ? 0 : 1)) % 24;
          } else if (fuzzyMinutes == 20) {
            top += locale["twenty"];
            middle += locale["past"];
          } else if (fuzzyMinutes == 15) {
            top += locale["quarter"];
            middle += locale["past"];
          } else if (fuzzyMinutes == 10) {
            top += locale["ten"];
            middle += locale["past"];
          } else if (fuzzyMinutes == 5) {
            top += locale["little"][fuzzyIndex];
            middle += locale["past"];
          }
        }
        if (fuzzyHours == 0) {
          bottom += locale["midnight"];
        } else if (fuzzyHours == 12) {
          bottom += locale["noon"];
          bottomFont = Graphics.FONT_MEDIUM;
        } else {
          bottom += locale["hours"][fuzzyHours % 12];
        }

        var topHeight = Graphics.getFontHeight(bottomFont);
        var middleHeight = Graphics.getFontHeight(bottomFont);
        var bottomHeight = Graphics.getFontHeight(bottomFont);
        var color = Graphics.COLOR_WHITE;
        var x = width / 2;
        var y = 2 * height / 5;

        drawString( dc, x, y - middleHeight/2 - topHeight, topFont, color, top);
        drawString( dc, x, y - middleHeight/2, middleFont, color, middle);
        drawString( dc, x, y + middleHeight/2, bottomFont, color, bottom);

    }

    // This method is called when the device re-enters sleep mode.
    // Set the isAwake flag to let onUpdate know it should stop rendering the second hand.
    function onEnterSleep() {
        isAwake = false;
        WatchUi.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    // Set the isAwake flag to let onUpdate know it should render the second hand.
    function onExitSleep() {
        isAwake = true;
    }
}

class AboutTimeDelegate extends WatchUi.WatchFaceDelegate {
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
    }
}
