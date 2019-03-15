using Toybox.System;
using Toybox.Test;

(:test)
class AboutTimeTest {

  (:test)
  function testTimes(logger) {
    var view = new AboutTimeView();
    var time = System.getClockTime();
    view.readLocale();
    for (var hour=0; hour<24; hour++) {
      time.hour = hour;
      for (var min=0; min<60; min+=5) {
        time.min = min;
        var currentLocale = view.localize();
        if (view has :prepareStrings) {
          var dict = view.prepareStrings(time, currentLocale);
          var str = dict[:top] + " " + dict[:middle] + " " + dict[:bottom];
          logger.debug(time.hour + ":" + time.min.format("%02d") + " = " + str);
          if (str.length() < 4) {
            logger.warning("Short string: " + time.hour + ":" + time.min.format("%02d") + " = " + str);
            return false;
          }
        }
        else {
          logger.debug("here");
          return false;
        }
      }
    }
    return true;
  }

}
