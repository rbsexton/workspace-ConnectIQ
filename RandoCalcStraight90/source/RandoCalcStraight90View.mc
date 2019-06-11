using Toybox.WatchUi as Ui;

class RandoCalcStraight90View extends Ui.SimpleDataField {

   //! Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "Banked";
    }

	// var itemcount = 0;
	// var printcount = 0;
    //! The given info object contains all the current workout
    //! information. Calculate a value and return it in this method.
    
    
    // Take two - do it all in minutes.
    // distance (m)  * (5400min/1,200,000m) = distance * 9/2000    ( 15kph )
    // 90-Hour Straight Time, Cascades-1200 style.
    // Table from RUSA (90-hour ACP), simplified for closing only. 
   function compute(info) {
   		if ( info.elapsedDistance == null ||
   		     info.elapsedTime == null ) {
   			return(0);
   			}
  
   		var closetime_mins;
   		var elapsed_mins;
   		elapsed_mins = (info.elapsedTime * .0000166666 );

   		closetime_mins = info.elapsedDistance * .0045 ; // 9/2000
  
   		// Sys.println(info.elapsedDistance/1000,  ideal);
   		// Sys.println(ideal);
   		// itemcount = itemcount + 1;
   		// printcount = printcount + 1;
   		// if ( printcount >= 10 ) {
   		//	printcount = printcount - 10;
   		//	Sys.print(itemcount); Sys.print(" ");
   		//	Sys.print(elapsed_mins); Sys.print(" ");
   		//	Sys.print(closetime_mins); Sys.print(" ");
   		//	Sys.println(info.elapsedDistance/1000);
		//	}			
   		return(closetime_mins - elapsed_mins);
    }
}
