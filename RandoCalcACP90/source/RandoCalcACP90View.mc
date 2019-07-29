using Toybox.WatchUi;

// Version 1.1.0
//
// Banked time - For a given distance, calculate how how long it should take.
    // This has proven more difficult than I suspected, due to the 
    // variety of calculation methods out there.
    
    // Table from RUSA (90-hour ACP), simplified for closing only. 
    // 0-600km, 40 h - distance (m)  * (60min/15000m) = distance/250   ( 15kph ) 
    // 601-1000km, 35h - distance (m)  * (2100min/400000m) = 21min/4000m = distance / 190.48   ( 11.4kph ) 
    // 1001-1300km,  22.5h -  1350min/300,000m = 135/30,000 = 9/2000


class RandoCalcACP90View extends WatchUi.SimpleDataField {

	// Distance Offset, Minutes Offset, Minutes/meter for this leg.
	// For a 200k, you get an extra 10m
	const lut = [
		[       0,    0, 0.004050000 ],
		[  200000,  810, 0.003900000 ],
		[  300000, 1200, 0.004200000 ],
		[  400000, 1620, 0.003900000 ],		
		[  600000, 2400, 0.005250000 ],		
		[ 1000000, 4500, 0.004511278 ],		
		[ 0, 0, 0 ] // Mark the end of the list.
		];
   // --------------------------------------------------------------
   // CUT HERE   
   // --------------------------------------------------------------

   //! Set the label of the data field here.
	var table_entry;
	
    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "Banked";
        table_entry = 0;
    }

     
    // Take two - do 
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
   		
   		// First, we need to figure out which entry.
   		// Simplify this to a check for the next one.
   		var i = table_entry + 1;
   		
   		// If the next entry is less than the distance so far
   		// and the next entry isn't zero, use that one.
   		if ( lut[i][0] != 0 && info.elapsedDistance > lut[i][0] ) {
   			 table_entry = i; // Save state!
   			 }
   		else { i = table_entry; }
   		
   		
   		// Now we've ID'd the table entry to use.
   		var base_mins  = lut[i][1];
   		var leg_ridden = info.elapsedDistance - lut[i][0];
   		var leg_minutes_allowed = leg_ridden * lut[i][2];
   		
   		closetime_mins = base_mins + leg_minutes_allowed; 	
   		 
   		// System.print("i"); System.print(i); 
   		// System.print(" d"); System.print(info.elapsedDistance); 
    	// System.print(" e");  System.print(elapsed_mins); 
    	 
    	// var speed = info.elapsedDistance * .001 / (elapsed_mins/60);
    	 
    	// System.print(" kph:"); System.print(speed); 

    	// System.print(" c"); System.print(closetime_mins); 
    	// System.println(" ");
    	 		 	
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
   // --------------------------------------------------------------
   // CUT HERE   
   // --------------------------------------------------------------
   		
   		
    }

}
