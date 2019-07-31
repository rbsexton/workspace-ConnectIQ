using Toybox.WatchUi;

class RandoCalcPBP80View extends WatchUi.SimpleDataField {

	// Distance Offset, Minutes Offset, Minutes/meter for this leg.
	const lut = [
		[       0,    0, 0.003525346 ],
		[  217000,  765, 0.003539326 ],
		[  306000, 1080, 0.003518519 ],
		[  360000, 1270, 0.003752941 ],		
		[  445000, 1589, 0.003750000 ],		
		[  521000, 1874, 0.003752809 ],		
		[  610000, 2208, 0.004024096 ],		
		[  693000, 2542, 0.003977778 ],		
		[  783000, 2900, 0.004023256 ],		
		[  869000, 3246, 0.004222222 ],		
		[  923000, 3474, 0.004292135 ],		
		[ 1012000, 3856, 0.004470588 ],		
		[ 1097000, 4236, 0.004649351 ],		
		[ 1174000, 4594, 0.004577778 ],		
		[ 1219000, 4800, 0.004577778 ],		
		[ 0, 0, 0 ] // Mark the end of the list.
		];
   // --------------------------------------------------------------
   // CUT HERE - Based upon the PBP-84h calculator.
   // --------------------------------------------------------------

	var table_entry;
	
    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "Banked80";
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