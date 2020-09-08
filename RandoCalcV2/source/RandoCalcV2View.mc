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
	
    // Set the label of the data field here.
    function initialize() {
        DataField.initialize();
        BankedTime = 0.0f;
        PreviousBanked = 0.0f;
        table_entry = 0;
        trend = " ";
        trend_downcounter = 4;
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
    
    
    	// Now we format it according to magnitude
    	if ( banked < 1.0 ) { // Minutes
    		var seconds = banked * 60.0f;
    		seconds = seconds.toNumber(); // Round to an integer.
    		formatted = seconds.format("%d") + "s";
    		}
    	else if ( banked < 60.0 ) {
			// Calculate minutes and seconds.    	
    		var m = banked.toNumber();
    		var s = ( banked - m ) * 60.0f;
    		s = s.toNumber();
    		
    		formatted = m.format("%d") + "m" + s.format("%02d");  	
    		}
    	else {
    		// Convert this into hours.
    		var x = banked * ( 0.0166666666666666666666666f ); // divide by 60 
    		var h = x.toNumber();
    		var m = (x - h) * 60.0f ; // back to minutes. 
    		m = m.toNumber();
    		
    		formatted = h.format("%d") + "h" + m.format("%02d") + trend;  		
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
