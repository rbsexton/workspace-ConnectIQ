using Toybox.WatchUi;

// Version 2.0.0
// Switch over to the table-driven code from the PBP calculators.


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
   // CUT HERE - Master Code from PBP84
   // --------------------------------------------------------------

	var table_entry;
	
    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "Banked";
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
   		 
   		return(closetime_mins - elapsed_mins);
   // --------------------------------------------------------------
   // CUT HERE   
   // --------------------------------------------------------------
   		
    }

}
