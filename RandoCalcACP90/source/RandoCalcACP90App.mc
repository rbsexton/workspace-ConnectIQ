using Toybox.Application;

class RandoCalcACP90App extends Application.AppBase {

	// initialize the AppBase class
    function initialize() {
        AppBase.initialize();
    }
   
    //! onStart() is called on application start up
    function onStart(state) {
    	return false;
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
    	return false;
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new RandoCalcACP90View() ];
    }

}