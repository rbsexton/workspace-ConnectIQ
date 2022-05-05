using Toybox.WatchUi;
using Toybox.Graphics;

class RandoCalcV2View extends WatchUi.DataField {


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

    hidden var BankedTime; // Final calulated value.
    hidden var mValueLast; //
    hidden var PreviousBanked;
    hidden var trend;
    hidden var trend_downcounter;  
        
	hidden var table_entry;
	
	hidden var banked_fake;
	
	
    // Set the label of the data field here.
    function initialize() {
        DataField.initialize();
        BankedTime = 0.0f;
        PreviousBanked = 0.0f;
        table_entry = 0;
        trend = " ";
        trend_downcounter = 4;
        banked_fake = 0.75f;
	    }


	// Generate a monotonic counter that triggers the different 
	// display formats.
	function simulate() {
	
		if ( banked_fake > 1.25 && banked_fake < 1.5 ) { // Seconds to minutes.
			banked_fake = 89.75; 
			}
		else if ( banked_fake > 90.25 &&  banked_fake < 91.0 ) { // 90 minutes to hours.
			banked_fake = 119.5;
			}
		else if ( banked_fake > 120.5 && banked_fake < 121.0  ) { // hours to tens of hours.
			banked_fake = 599.75;
			}
			

		banked_fake = banked_fake + 0.016103; // Prime-ish
	
		}
		



    function compute(info) {
    
   		if ( info.elapsedDistance == null || info.elapsedTime == null ) {
   			BankedTime = 0.0f;
   			return;
   			}
  
  		// Calculate the trend every 5s.
  		if ( trend_downcounter == 0 ) {
  			trend_downcounter = 4;
  			
  			if ( BankedTime > PreviousBanked ) {
  				trend = "+";
  				}
  			else { 
  				trend = "-";
  				}
  			
  			PreviousBanked = BankedTime;
  			}
  		else { 
  			trend_downcounter = trend_downcounter - 1;
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
   		 
   		BankedTime = (closetime_mins - elapsed_mins);
   		
   		simulate();
   		BankedTime  = banked_fake;
   		
   		return; 
    }
   // --------------------------------------------------------------
   // CUT HERE   
   // --------------------------------------------------------------
   		
 
    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        var obscurityFlags = DataField.getObscurityFlags();

        // Top left quadrant so we'll use the top left layout
        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.TopLeftLayout(dc));

        // Top right quadrant so we'll use the top right layout
        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.TopRightLayout(dc));

        // Bottom left quadrant so we'll use the bottom left layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

        // Bottom right quadrant so we'll use the bottom right layout
        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
            View.setLayout(Rez.Layouts.BottomRightLayout(dc));

        // Use the generic, centered layout
        } else {
            View.setLayout(Rez.Layouts.MainLayout(dc));
            var labelView = View.findDrawableById("label");
            labelView.locY = labelView.locY - 16;
            var valueView = View.findDrawableById("value");
            valueView.locY = valueView.locY + 7;
        }

        View.findDrawableById("label").setText(Rez.Strings.label);
        return true;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    // Make a local copy of the Calculated value because the 
    // two routines run asyncronously.   This is probably not a hazard,
    // but better to be safe.
    function onUpdate(dc) {
    
    	var inthehole; 
    	var banked;
    	var formatted;
    	
    	// First order of business.  Positive or negative?
    	if ( BankedTime < 0 ) {
    		inthehole = true;
    		banked = BankedTime.abs();
    		formatted = "-";
    		}
    	else {
    		inthehole = false;
    		banked = BankedTime;
    		formatted = "";
    		}
    
    
    	// Now we format it according to magnitude.
    	// There are about 6 digits to work with.
    	
    	// ---------------- Seconds ----------------
    	// XXs 
    	System.println(banked);
    	
    	if ( banked < 1.0 ) { // Seconds
    		var seconds = banked * 60.0f;
    		seconds = seconds.toNumber(); // Round to an integer.
    		formatted = seconds.format("%d") + "s";
    		}
    	// ---------------- Up to 90 Minutes ----------------
    	// XXmSS
    	else if ( banked < 90.0 ) { // Minutes and seconds.
    		var m = banked.toNumber();
    		var s = ( banked - m ) * 60.0f;
    		s = s.toNumber();
    		
    		formatted = m.format("%d") + "m" + s.format("%02d");  	
    		}
    
		// For long durations, we pull out hours, minutes and seconds.
    	else {
    	    var b_hours = banked * ( 0.0166666666666666666666666f ); // divide by 60
    		
    		var h = b_hours.toNumber();
    		var m = banked - (h * 60.0f); // back to minutes with fractional minutes.

	    	// ---------------- Up to 10 Hours ----------------
	    	// XhYY:ZZ 
			if ( banked < 600.0 ) {
				// Minutes and seconds conversion to integers.
	    		var s = (m - m.toNumber()) * 60.0f; 

	    		m = m.toNumber();
	    		s = s.toNumber();
	    		
	    		formatted = h.format("%d") + "h" +  m.format("%02d") + ":" + s.format("%02d");  				
	    		// formatted = h.format("%d") + "h" +  m.format("%02.2f");  				
				}
	    	// ---------------- Over 10 Hours ----------------
	    	// XXhMM.M 
			else {			
			System.println("m +" + m);
				// It looks like the garmin formatter isn't as flexible as I would like.
				// Look for short minutes and add the leading zero as a character.
				if ( m < 10.0f ) {
		    		formatted = h.format("%d") + "h0" + m.format("%0.1f");  				
					}
				else {
					formatted = h.format("%d") + "h" + m.format("%0.1f");  				
					}
					
				}

    		}
    	    	
    	if ( inthehole ) {
    		if ( getBackgroundColor() == Graphics.COLOR_BLACK ) {
    			View.findDrawableById("Background").setColor(Graphics.COLOR_WHITE);
    			
    			View.findDrawableById("label").setColor(Graphics.COLOR_BLACK);	
 				View.findDrawableById("value").setColor(Graphics.COLOR_BLACK);
    			}
    		else {
 				View.findDrawableById("Background").setColor(Graphics.COLOR_BLACK);

 				View.findDrawableById("label").setColor(Graphics.COLOR_WHITE);
 				View.findDrawableById("value").setColor(Graphics.COLOR_WHITE); 			
    			}

			View.findDrawableById("label").setText("Late");
    		}
 		else { 
 			if ( getBackgroundColor() == Graphics.COLOR_BLACK ) {
 				View.findDrawableById("Background").setColor(Graphics.COLOR_BLACK);
 				
 				View.findDrawableById("label").setColor(Graphics.COLOR_WHITE);
 				View.findDrawableById("value").setColor(Graphics.COLOR_WHITE); 			
 				}
 			else {
    			View.findDrawableById("Background").setColor(Graphics.COLOR_WHITE);
    			
    			View.findDrawableById("label").setColor(Graphics.COLOR_BLACK);			
 				View.findDrawableById("value").setColor(Graphics.COLOR_BLACK);
 				}
 				
			View.findDrawableById("label").setText("Banked");
 			}   
    
    	
        // Set the background color
        //View.findDrawableById("Background").setColor(getBackgroundColor());

        // Set the foreground color and value
        //var value = View.findDrawableById("value");
        //if (getBackgroundColor() == Graphics.COLOR_BLACK) {
         //   value.setColor(Graphics.COLOR_WHITE);
        //} else {
        //    value.setColor(Graphics.COLOR_BLACK);
        //}

        View.findDrawableById("value").setText(formatted);

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
