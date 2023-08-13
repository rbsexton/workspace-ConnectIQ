using Toybox.WatchUi;

// ---------------------------------------------------------------
// ---------------------------------------------------------------
// Primary data point collection.
// ---------------------------------------------------------------
// ---------------------------------------------------------------
const data_points_size = 64;  // ATTN! Must be 2^N
const data_points_mask = data_points_size - 1;  

// ---------------------------------------------------------------
// ---------------------------------------------------------------
// Do the numerics and return the final result.
// NOTE NOTE NOTE.    This all appears to be redundant, 
// because the things that we need are in the 'info'
// object.   But thats not the case, because of the circular 
// buffer.  
// ---------------------------------------------------------------
// ---------------------------------------------------------------
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

// ---------------------------------------------------------------
// ---------------------------------------------------------------
// ------------------------------------------------------------
// Sampling theory.    
// The unit of measurement is Milliseconds, so its not really possible 
// to do long intervals and get the math right for 32-bit numbers 
// Plan - Generate a once per minute signal and divided that down. 
// ---------------------------------------------------------------
// ---------------------------------------------------------------
// ---------------------------------------------------------------
class MovingAverage {
    var pdp_sample_i;         // This points to the next value to write. 

    var data_timerTime       ;
    var data_elapsedDistance ;
    var data_totalAscent     ;
    
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
        ww_pace = 0.0;

        data_timerTime       = new [data_points_size];
        data_elapsedDistance = new [data_points_size];
        data_totalAscent     = new [data_points_size];

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

    function interp_ready() {
        return ( pdp_sample_i >= data_points_size );
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

            // Make sure that there is enough data.
            if ( pdp_sample_i < data_points_size ) {
                ww_pace = 0.0;
                return; 
            }

            var t0  =   pdp_sample_i       & data_points_mask; // Oldest.
            var t   = ( pdp_sample_i - 1 ) & data_points_mask; // Now.

            var time   = data_timerTime[t] - data_timerTime[t0];
            var dist   = data_elapsedDistance[t] - data_elapsedDistance[t0];
            var ascent = data_totalAscent[t] - data_totalAscent[t0];
            
            ww_pace = analyze(time, dist, ascent);

        }
    }

}

// ---------------------------------------------------------------
// ---------------------------------------------------------------
// ---------------------------------------------------------------
// Primary Class
// ---------------------------------------------------------------
// ---------------------------------------------------------------
// ---------------------------------------------------------------
class WWPaceCalcView extends WatchUi.SimpleDataField {

    var Pace; // This gets displayed.

    var         interp = [ null,      null,     null,     null,     null,  null ];
    const method_names = ["Pace", "Pace 1", "Pace 2", "Pace 4", "Pace 8", "24 H"];

    // ------------------------------------
    // Display Logic.

    var   d_cycle      = 15; // Count this down to cycle the field. 
    const d_cycle_init = 15; // Reset Value. 

    var   d_index     = 0;  // Zero means 'Whole Ride'  Matches the labels.
    const d_index_max = 5;

    // ----------------------------------------
    // Set the label of the data field here.
    // ----------------------------------------
    function initialize() {
        System.println("Starting");
        
        SimpleDataField.initialize();

        interp[1] = new MovingAverage(   1); // 1
        interp[2] = new MovingAverage(   2); // 2
        interp[3] = new MovingAverage( 240); // 4
        interp[4] = new MovingAverage( 480); // 8
        interp[5] = new MovingAverage(1440); // 24

        // TODO Add code here to look things up.
        // Zero means 'Whole Ride'

        // label = "<>";
    }

    // ----------------------------------------
    // ----------------------------------------
    function next_display() {
        d_cycle = d_cycle - 1; 
        if ( d_cycle > 0 ) {
            return;
            } 

        // Otherwise get to work. 
        d_cycle = d_cycle_init;

        d_index = d_index + 1; 
        if ( d_index > d_index_max ) {
            d_index = 0; 
        }

        // Now check for validity.  If non-zero and not ready, reset to zero. 
        if ( d_index && !interp[d_index].interp_ready() ) {
            d_index = 0; 
            }

        // self.label = method_names[d_index];
    }

    // ----------------------------------------
    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    // ----------------------------------------
    function compute(info) {

        next_display();

        // The interpolator has to run at all times, or 
        // it will get stuck and never recover. 
        var now  = System.getTimer();

        // All hell breaks loose when now = 0, because divide by zero.
        if ( now == 0 ) { Pace = 0.0; return(Pace); }

        // Check for unstarted ride and return 0. 
        if (info.totalAscent     == null ||
            info.elapsedDistance == null ||
            info.averageSpeed    == null ) {
            System.println("compute() - nulls");
    
            interp[1].service(now, info.timerTime, 0, 0);
            interp[2].service(now, info.timerTime, 0, 0);
            interp[3].service(now, info.timerTime, 0, 0);
            interp[4].service(now, info.timerTime, 0, 0);
            interp[5].service(now, info.timerTime, 0, 0);

            Pace = 0.0;
        	return(Pace);			        
			}             

        // Otherwise, normalcy. 
        interp[1].service(now, info.timerTime, info.elapsedDistance, info.totalAscent);
        interp[2].service(now, info.timerTime, info.elapsedDistance, info.totalAscent);
        interp[3].service(now, info.timerTime, info.elapsedDistance, info.totalAscent);
        interp[4].service(now, info.timerTime, info.elapsedDistance, info.totalAscent);
        interp[5].service(now, info.timerTime, info.elapsedDistance, info.totalAscent);

        // The math can produce crazy results when you don't 
        // have enough data, so don't calculate that.

        // If its too soon to collect useful data, return. 
        if ( info.elapsedDistance < 500 ) { 
            // System.println("compute() - too soon");
            System.println("compute() - too soon ");
            Pace = 0.0;
            return(Pace);
            }

        if ( d_index ) {
            Pace = interp[d_index].ww_pace;
            return(Pace); 
        } else {
            Pace = analyze(info.timerTime, info.elapsedDistance, info.totalAscent);
            return(Pace);
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

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    //function onUpdate(dc) {

        //var formatted =  Pace.format("%2.1f");  
        //View.findDrawableById("value").setText(formatted);
        // View.findDrawableById("label").setText("Label");

        // Paint the screen.        
        //View.onUpdate(dc);
    // }


}