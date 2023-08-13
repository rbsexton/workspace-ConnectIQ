using Toybox.WatchUi;


// -----------------------------------
// Primary data point collection.
const data_points_size = 64;  // ATTN! Must be 2^N
const data_points_mask = data_points_size - 1;  

// Do the numerics and return the final result.
// NOTE NOTE NOTE.    This all appears to be redundant, 
// because the things that we need are in the 'info'
// object.   But thats not the case, because of the circular 
// buffer.  
function analyze(timerTime, elapsedDistance, totalAscent) {

    // Calculate averate speed. 
    timerTime /= 1000.0; // Seconds. 
    var averageSpeed = elapsedDistance / timerTime;
    var avg_mph      = 2.23694 * averageSpeed;

    // Western Wheelers Pace: Average Speed + Hilliness
    // Where Hilliness is feet/mile/25
    // All of this has been converted to Metric.

    // Hilliness = 0.211286 m / km

    var hilliness =  (211.286 * totalAscent) / ( elapsedDistance );

    var pace = hilliness + avg_mph;

    // {
    //    var speed_mph = info.currentSpeed * 2.23694;
    //    System.print  ("t=" + timerTime + ",v=" + speed_mph + ",avg=");
    //    System.println(avg_mph + ",climb=" + totalAscent);
    // }

    return(pace);
    }



// ------------------------------------------------------------
// Sampling theory.    
// The unit of measurement is Milliseconds, so its not really possible 
// to do long intervals and get the math right for 32-bit numbers 
// Plan - Generate a once per minute signal and divided that down. 
class MovingAverage {
    var pdp_sample_i;          // This points to the next value to write. 

    var data_timerTime;
    var data_elapsedDistance;
    var data_totalAscent;

    var ww_pace;

    // -----------------------------------
    // SAMPLE INTERPOLATOR 
	// The timeout determines the baseline sampling rate.
    // Keep at most a hour of data.
    // -----------------------------------
    var   timebase_interval_ms;  
	var   timebase_err;        // The countdown variable.
	var   timebase_last_ms;    // Used to generate the delta. 

    function initialize(sample_interval_minutes) {
        pdp_sample_i = 0;

        data_timerTime       = new [ data_points_size ]; 
        data_elapsedDistance = new [ data_points_size ]; 
        data_totalAscent     = new [ data_points_size ]; 

        ww_pace      = 0.0;

        // Initialize the buffers so that the calculation 
        // code can run from the very beginning.
        var i = 0; 
        for ( i = 0; i < data_points_size; i++) {
            data_timerTime      [i] =   0; // This shows up as a 'number' 
            data_elapsedDistance[i] = 0.0; 
            data_totalAscent    [i] = 0.0; 
        }

        // Calculate the update interface for the main timing loop.  
        // there are 64 samples.
        timebase_last_ms = 0; 
        timebase_interval_ms = ( sample_interval_minutes * 60.0 ) / data_points_size;  
        timebase_interval_ms *= 1000;

        timebase_err         = timebase_interval_ms / 2; 
    }

    // Update the running timebase/iterpolator. 
    // return a 1 if its time to add a new sample.
    function interpolate(now) {
        var duration = now - timebase_last_ms;
        timebase_last_ms = now;

        timebase_err -= duration; // Use Bresenhams Algorithm.

        if ( timebase_err  <= 0 ) {
            timebase_err += timebase_interval_ms;
            return(1);
        }
        else {
            return(0);
        }
    }

    // Add a sample and return the new pace information.
    function add_sample(tTime, eDistance, totAscent) {
        var i = pdp_sample_i & data_points_mask;

        data_timerTime      [i] = tTime;  
        data_elapsedDistance[i] = eDistance;
        data_totalAscent    [i] = totAscent;

        pdp_sample_i++;
    }

    // Call this every time.  If something changes, update wwpace.
    function service(now, tTime, eDistance, totAscent) {
        if ( self.interpolate(now) ) {
            self.add_sample(tTime, eDistance, totAscent);

            var t0  =   pdp_sample_i       & data_points_mask; // Oldest.
            var t   = ( pdp_sample_i - 1 ) & data_points_mask; // Now.

            var time   = data_timerTime[t] - data_timerTime[t0];  
            var dist   = data_elapsedDistance[t] - data_elapsedDistance[t0];
            var ascent = data_totalAscent[t] - data_totalAscent[t0];
            
            ww_pace = analyze(time, dist, ascent);

        }
    }

    function interp_ready() {
        return ( pdp_sample_i >= data_points_size );
    }
}

// ---------------------------------------------------------------
// Primary Class
// ---------------------------------------------------------------
class WWPaceCalcView extends WatchUi.SimpleDataField {

    // -----------------------------------
    // Data points. 
	var data_timerTime;
	var data_elapsedDistance;
	var data_totalAscent;
    
    var interp240; // The interpolator.

    // ------------------------------------
    // Keep state across invocations, to avoid 
    // calculations when there is no new data. 
    var   ww_pace; 

    // ------------------------------------
    // This is the knob that indicates how 
    // long the measurement window is. 
    var sample_interval_minutes; 

    // Set the label of the data field here.
    function initialize() {
        System.println("Starting");
        
        SimpleDataField.initialize();

        interp240 = new MovingAverage(240);
        
        // TODO Add code here to look things up.
        // Zero means 'Whole Ride'
        sample_interval_minutes = Application.Properties.getValue("interval");

        label = "Pace240";
    }


    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {

        // The interpolator has to run at all times, or 
        // it will get stuck and never recover. 
        var now  = System.getTimer();

        // Check for unstarted ride and return 0. 
        if (info.totalAscent     == null ||
            info.elapsedDistance == null ||
            info.averageSpeed    == null ) {
            System.println("compute() - nulls");
    
            interp240.service(now, info.timerTime, 0, 0);

        	return(0);			        
			}             

        // Otherwise, normalcy. 
        interp240.service(now, info.timerTime, info.elapsedDistance, info.totalAscent);

        // The math can produce crazy results when you don't 
        // have enough data, so don't calculate that.

        // If its too soon to collect useful data, return. 
        if ( info.elapsedDistance < 500 ) { 
            // System.println("compute() - too soon");
            System.println("compute() - too soon ");
            return(0);
            }

        // No data point.   If we're spun up, shortcut until there is a 
        // full set of data, otherwise, calculate based upon current stats. 
        if ( interp240.interp_ready() ) { // Full dataset case. 
                return(interp240.ww_pace);
        } else {
            ww_pace = analyze(info.timerTime, info.elapsedDistance, info.totalAscent);
            return(ww_pace);
        }
        

		// A little debug code, since retired.                
   		// itemcount = itemcount + 1;
   		// printcount = printcount + 1;
   		// if ( printcount >= 10 ) {
   		//	printcount = printcount - 10;
   		//	Sys.print(itemcount); Sys.print(" ");
   		//	Sys.print(info.elapsedDistance/1000);  Sys.print(" ");
   		//	Sys.print(info.totalAscent); Sys.print(" ");
   		//	Sys.print(avg_mph); Sys.print(" ");
   		//	Sys.println(hilliness); 
		//	}			
    }

}