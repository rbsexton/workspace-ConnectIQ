using Toybox.Application;

// See RandoCalcPBP84hView for details on the algorithm.


class RandoCalcPBP84hApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new RandoCalcPBP84hView() ];
    }

}