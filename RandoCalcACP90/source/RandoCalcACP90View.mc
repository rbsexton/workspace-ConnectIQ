using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

// Version 1.1.0
//
// Banked time - For a given distance, calculate how how long it should take.
    // This has proven more difficult than I suspected, due to the 
    // variety of calculation methods out there.
    
    // Table from RUSA (90-hour ACP), simplified for closing only. 
    // 0-600km, 40 h - distance (m)  * (60min/15000m) = distance/250   ( 15kph ) 
    // 601-1000km, 35h - distance (m)  * (2100min/400000m) = 21min/4000m = distance / 190.48   ( 11.4kph ) 
    // 1001-1300km,  22.5h -  1350min/300,000m = 135/30,000 = 9/2000


class RandoCalcACP90View extends Ui.SimpleDataField {
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
    // distance (m)  * (60min/15000m) = distance/250   ( 15kph )
    // Table from RUSA (90-hour ACP), simplified for closing only. 
    // RUSA Says 601-1000 = 13.kph.
    // 11430m = 3600s.  s/m = 3600/11430 
    // 15000m = 3600s   s/m = 3600/15000
   function compute(info) {
   		if ( info.elapsedDistance == null ||
   		     info.elapsedTime == null ) {
   			return(0);
   			}
  
   		var closetime_mins;
   		var elapsed_mins;
   		elapsed_mins = (info.elapsedTime * .0000166666 );
   		
   		if ( info.elapsedDistance <= 600000 ) {
   		 	closetime_mins = info.elapsedDistance * .004 ; // 1/250
   		 	}
   		else if ( info.elapsedDistance > 600000 && info.elapsedDistance <= 1000000 ) { 
 			closetime_mins = 2400 + (( info.elapsedDistance - 600000 )	* 0.00525 );	
   			}
   		else { // 1000-1300km
 			closetime_mins = 4500 + (( info.elapsedDistance - 1000000 )	* 0.0045 );	
   			}

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
