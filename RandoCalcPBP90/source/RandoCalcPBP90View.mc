using Toybox.WatchUi;

class RandoCalcPBP90View extends WatchUi.SimpleDataField {
	// Distance, Minutes, Minutes/meter for this leg.
	const lut = [
		[       0,    0, 0.004000000 ],
		[  217000,  868, 0.004000000 ],
		[  306000, 1224, 0.004277778 ],
		[  360000, 1455, 0.004282353 ],		
		[  445000, 1819, 0.004289474 ],		
		[  521000, 2145, 0.004280899 ],		
		[  610000, 2526, 0.004313253 ],		
		[  693000, 2884, 0.004544444 ],		
		[  783000, 3293, 0.004639535 ],		
		[  869000, 3692, 0.004611111 ],		
		[  923000, 3941, 0.004775281 ],		
		[ 1012000, 4366, 0.004964706 ],		
		[ 1097000, 4788, 0.005038961 ],		
		[ 1174000, 5176, 0.004977778 ],		
		[ 1219000, 5400, 0.004977778 ],		
		[ 0, 0, 0 ] // Mark the end of the list.
		];
   // --------------------------------------------------------------
   // CUT HERE   
   // --------------------------------------------------------------

	var table_entry;
	
    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "Banked90";
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
    }
   // --------------------------------------------------------------
   // CUT HERE   
   // --------------------------------------------------------------


}