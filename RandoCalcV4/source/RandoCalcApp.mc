import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// These two are the only globals. 
// They're here to support re-configuration on the fly 
// via the ConnectIQ app.
var engine         as RandoCalcEngine or Null;
var verbose        as Boolean or Null;

class RandoCalcApp extends Application.AppBase {

    function apply_config() {
        // ------------------------------------------
        // Choose the look-up table. 
        // ------------------------------------------
        var which_flavor = Application.Properties.getValue("method");
        engine = new RandoCalcEngine(which_flavor);

        // ------------------------------------------
        // Display Format/Verbosity.
        // ------------------------------------------
        verbose           = Application.Properties.getValue("ui_verbose");
    }

    function initialize() {
        AppBase.initialize();
    }

    function onSettingsChanged() {
        apply_config();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        apply_config();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

   //! Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new RandoCalcView() ];
    }

}

function getApp() as RandoCalcApp {
    return Application.getApp() as RandoCalcApp;
}

