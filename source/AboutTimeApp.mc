using Toybox.Application;
using Toybox.Time;
using Toybox.Communications;

class AboutTime extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [new AboutTimeView(), new AboutTimeDelegate()];
        } else {
            return [new AboutTimeView()];
        }
    }

}
