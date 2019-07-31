using Toybox.WatchUi;
using Toybox.System;

// Control Close Calculator for PBP 2019, 84h
// ACP Control close times for PBP appear to be adjusted a bit
// from control to control, so they are more complex than
// the version that we use in the US.

// This calculator uses a lookup table to correct for the variation.
// it calculates your progress since the last control, rather than
// over the whole event.  

// The table below is based upon the ACP published times.
// This calculator uses meters (as does the GPS) and minutes.
// The coefficient is minutes per meter, so control close time
// is minutes/meter * meters.

class RandoCalcPBP84hView extends WatchUi.SimpleDataField {

	// Distance Offset, Minutes Offset, Minutes/meter for this leg.
	const lut = [
		[       0,    0, 0.003626728 ],
		[  217000,  787, 0.003752809 ],
		[  306000, 1121, 0.003740741 ],
		[  360000, 1323, 0.003752941 ],		
		[  445000, 1642, 0.004000000 ],		
		[  521000, 1946, 0.004000000 ],		
		[  610000, 2302, 0.004024096 ],		
		[  693000, 2636, 0.004122222 ],		
		[  783000, 3007, 0.004313953 ],		
		[  869000, 3378, 0.004425926 ],		
		[  923000, 3617, 0.004617978 ],		
		[ 1012000, 4028, 0.004717647 ],		
		[ 1097000, 4429, 0.005025974],		
		[ 1174000, 4816, 0.004977778 ],		
		[ 1219000, 5040, 0.004977778 ],		
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
        label = "Banked84";
        table_entry = 0;
    }

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
   		
   		// If the next entry distance is less than the distance so far
   		// and the next entry isn't zero, use the next one.
   		if ( lut[i][0] != 0 && info.elapsedDistance > lut[i][0] ) {
   			 table_entry = i; // Save state!
   			 }
   		else { i = table_entry; }
   		
   		
   		// Now we've ID'd the table entry to use.
   		var base_mins  = lut[i][1];
   		var leg_ridden = info.elapsedDistance - lut[i][0];
   		var leg_minutes_allowed = leg_ridden * lut[i][2];
   		
   		closetime_mins = base_mins + leg_minutes_allowed; 	
   		
   		// ---------------------------------------------------
   		 
   		// System.print("i"); System.print(i); 
   		// System.print(" d"); System.print(info.elapsedDistance); 
    	// System.print(" e");  System.print(elapsed_mins); 
    	 
    	// var speed = info.elapsedDistance * .001 / (elapsed_mins/60);
    	 
    	// System.print(" kph:"); System.print(speed); 

    	// System.print(" c"); System.print(closetime_mins); 

    	// System.print(" b"); System.print(closetime_mins - elapsed_mins); 
    	// System.println(" ");
    	 		 	
   		return(closetime_mins - elapsed_mins);
    }
   // --------------------------------------------------------------
   // CUT HERE   
   // --------------------------------------------------------------


}