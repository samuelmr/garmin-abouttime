//
// Copyright 2016-2017 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Application;

// var partialUpdatesAllowed = false;
var locale = {};

// This implements an AboutTime watch face
// Original design by Austen Harbour
class AboutTimeView extends WatchUi.WatchFace
{
    var font;
    var isAwake;
    var screenShape;
    var dndIcon;
    var offscreenBuffer;
    var dateBuffer;

    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
        screenShape = System.getDeviceSettings().screenShape;
    }

    // Configure the layout of the watchface for this device
    function onLayout(dc) {

        // If this device supports the Do Not Disturb feature,
        // load the associated Icon into memory.
        if (System.getDeviceSettings() has :doNotDisturb) {
            dndIcon = WatchUi.loadResource(Rez.Drawables.DoNotDisturbIcon);
        } else {
            dndIcon = null;
        }

        locale = WatchUi.loadResource(Rez.JsonData.stringsJSON);

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
        var targetDc = dc;

        width = targetDc.getWidth();
        height = targetDc.getHeight();

        // Fill the entire background with Black.
        targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        targetDc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

        // Draw the do-not-disturb icon if we support it and the setting is enabled
        if (null != dndIcon && System.getDeviceSettings().doNotDisturb) {
            targetDc.drawBitmap( width * 0.75, height / 2 - 15, dndIcon);
        }

        // Output the offscreen buffers to the main display if required.
        drawTimeStrings(dc);

        // Draw the battery percentage directly to the main screen.
        var dataString = (System.getSystemStats().battery + 0.5).toNumber().toString() + "%";

        // Also draw the background process data if it is available.
        var backgroundData = Application.getApp().temperature;
        if(backgroundData != null) {
            dataString += " - " + backgroundData;
        }

        drawString(dc, width/2, 3*height/4, Graphics.FONT_TINY, Graphics.COLOR_WHITE, dataString);

    }

    // Draw the date string into the provided buffer at the specified location
    function drawString( dc, x, y, font, color, string ) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, string, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawTimeStrings(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        //If we have an offscreen buffer that has been written to
        //draw it to the screen.
        if( null != offscreenBuffer ) {
            dc.drawBitmap(0, 0, offscreenBuffer);
        }

        var clockTime = System.getClockTime();

        var fuzzy_hours = clockTime.hour;
        var fuzzy_minutes = ((clockTime.min + 2) / 5) * 5;

        if (fuzzy_minutes > 55) {
          fuzzy_minutes = 0;
          fuzzy_hours += 1;
          if (fuzzy_hours > 23) {
            fuzzy_hours = 0;
          }
        }

        var top = "";
        var middle = "";
        var bottom = "";
        var top_font = Graphics.FONT_MEDIUM;
        var middle_font = Graphics.FONT_SMALL;
        var bottom_font = Graphics.FONT_LARGE;

        var fuzzy_index = 0;
        if (fuzzy_hours % 2) {
          fuzzy_index = 1;
        }

        if (fuzzy_minutes != 0 && (fuzzy_minutes >= 10 || fuzzy_minutes == 5 || fuzzy_hours == 0 || fuzzy_hours == 12)) {
          if (fuzzy_minutes == 55) {
            middle_font = Graphics.FONT_MEDIUM;
            middle += locale["almost"][fuzzy_index];
            fuzzy_hours = (fuzzy_hours + 1) % 24;
          } else if (fuzzy_minutes == 50) {
            top += locale["ten"];
            middle += locale["to"];
            fuzzy_hours = (fuzzy_hours + 1) % 24;
          } else if (fuzzy_minutes == 45) {
            top += locale["quarter"];
            middle += locale["to"];
            fuzzy_hours = (fuzzy_hours + 1) % 24;
          } else if (fuzzy_minutes == 40) {
            top += locale["twenty"];
            middle += locale["to"];
            fuzzy_hours = (fuzzy_hours + 1) % 24;
          } else if (fuzzy_minutes == 35) {
            top_font = Graphics.FONT_SMALL;
            middle_font = Graphics.FONT_MEDIUM;
            top += locale["little"][fuzzy_index];
            middle += locale["past"] + " " + locale["half"];
            fuzzy_hours = (fuzzy_hours + 1) % 24;
          } else if (fuzzy_minutes == 30) {
            middle += locale["half"];
            fuzzy_hours = (fuzzy_hours + 1) % 24;
          } else if (fuzzy_minutes == 25) {
            top_font = Graphics.FONT_SMALL;
            middle_font = Graphics.FONT_MEDIUM;
            top += locale["almost"][fuzzy_index];
            middle += locale["half"];
            fuzzy_hours = (fuzzy_hours + 1) % 24;
          } else if (fuzzy_minutes == 20) {
            top += locale["twenty"];
            middle += locale["past"];
          } else if (fuzzy_minutes == 15) {
            top += locale["quarter"];
            middle += locale["past"];
          } else if (fuzzy_minutes == 10) {
            top += locale["ten"];
            middle += locale["past"];
          } else if (fuzzy_minutes == 5) {
            top += locale["little"][fuzzy_index];
            middle += locale["past"];
          }
        }
        if (fuzzy_hours == 0) {
          bottom += locale["midnight"];
        } else if (fuzzy_hours == 12) {
          bottom += locale["noon"];
          bottom_font = Graphics.FONT_MEDIUM;
        } else {
          if ((fuzzy_hours % 12 == 7) || (fuzzy_hours % 12 == 8)) {
            bottom_font = Graphics.FONT_MEDIUM;
          }
          bottom += locale["hours"][fuzzy_hours % 12];
        }

        // var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
        // var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);

        var lineHeight = Graphics.getFontHeight(middle_font);
        var color = Graphics.COLOR_WHITE;

        drawString( dc, width / 2, height/2 - 3*lineHeight/2, top_font, color, top);
        drawString( dc, width / 2, height/2 - lineHeight/2, middle_font, color, middle);
        drawString( dc, width / 2, height/2 + lineHeight/2, bottom_font, color, bottom);

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
