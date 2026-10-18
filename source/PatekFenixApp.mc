import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! Patek FENIX — a black/silver luxury analog watch face for the fēnix 9 Pro 43mm.
class PatekFenixApp extends Application.AppBase {
    private var _view as PatekFenixView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new PatekFenixView();
        _view = view;
        if (WatchUi.WatchFace has :onPartialUpdate) {
            return [view, new PatekFenixDelegate(view)];
        }
        return [view];
    }

    //! Called when the user changes settings in Garmin Connect / Connect IQ.
    function onSettingsChanged() as Void {
        var view = _view;
        if (view != null) {
            view.reloadSettings();
        }
        WatchUi.requestUpdate();
    }
}
