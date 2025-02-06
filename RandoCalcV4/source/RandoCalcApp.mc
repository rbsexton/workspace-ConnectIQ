import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

var engine         as RandoCalcEngine;
var verbose        as Boolean;
var verbose_cutoff as Float;

class RandoCalcApp extends Application.AppBase {

    function apply_config() {
        // ------------------------------------------
        // Choose the look-up table. 
        // ------------------------------------------
        var which_flavor      = Application.Properties.getValue("method");
        engine = new RandoCalcEngine(which_flavor);

        // ------------------------------------------
        // Display Format/Verbosity.
        // ------------------------------------------
        verbose           = Application.Properties.getValue("ui_verbose");
        if ( verbose ) { verbose_cutoff = 90.0; }
        else           { verbose_cutoff = 60.0; } 
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
    function getInitialView() as Array<Views or InputDelegates>? {
        return [ new RandoCalcView() ] as Array<Views or InputDelegates>;
    }

}

function getApp() as RandoCalcApp {
    return Application.getApp() as RandoCalcApp;
}

