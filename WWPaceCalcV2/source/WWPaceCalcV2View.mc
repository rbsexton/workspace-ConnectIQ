import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// ---------------------------------------------------------------
// ---------------------------------------------------------------
// Primary Data Point collection.
// There is a running counter that gets masked on every access.
// ---------------------------------------------------------------
// ---------------------------------------------------------------
const pdp_count = 64;  // ATTN! Must be 2^N
const pdp_mask = pdp_count - 1;  

// ---------------------------------------------------------------
// ---------------------------------------------------------------
// Do the numerics. 
// timerTime is assumed not to be zero, but not everything that
// calls this code has that failure mode, so let the caller decide.
// ---------------------------------------------------------------
// ---------------------------------------------------------------
function analyze( timerTime as Number, elapsedDistance as Float, totalAscent as Float) as Float
{
    // Calculate averate speed. 
    timerTime        = timerTime / 1000.0; // Seconds. 
    var averageSpeed = elapsedDistance / timerTime;
    var avg_mph      = 2.23694 * averageSpeed;

    // Western Wheelers Pace: Average Speed + Hilliness
    // Where Hilliness is feet/mile/25
    // All of this has been converted to Metric.

    // Hilliness = 0.211286 m / km

    var hilliness = (211.286 * totalAscent) / ( elapsedDistance );

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
// to do long intervals and get the math right for 32-bit numbers.
//
// Use Bresenhams algorithm to periodically capture a sample and 
// get the math right regardless of the service interval.
//   
// Keep pdp_count Primary data Points
// ---------------------------------------------------------------
// ---------------------------------------------------------------
// ---------------------------------------------------------------
class MovingAverage {
    var pdp_sample_i as Number = 0;    // This points to the next value to write. 

    var data_timerTime       = new Array<Number>[pdp_count];
    var data_elapsedDistance = new Array<Float>[pdp_count];
    var data_totalAscent     = new Array<Float>[pdp_count];
    
    var ww_pace as Float = 0.0;

    // -----------------------------------
    // SAMPLE INTERPOLATOR 
	// The timeout determines the baseline sampling rate.
    // -----------------------------------
    var   timebase_interval_ms as Number;  
	var   timebase_err         as Number; // The countdown variable.
	var   timebase_last_ms     as Number; // Used to generate the delta. 

    (:typecheck(false))
    function initialize(sample_interval_minutes as Number) {

        // Initialize the buffers so that the calculation 
        // code can run from the very beginning.
        var i = 0; 
        for ( i = 0; i < pdp_count; i++) {
            data_timerTime      [i] = 0;   // This shows up as a 'number' 
            data_elapsedDistance[i] = 0.0; 
            data_totalAscent    [i] = 0.0; 
        }

        // Calculate the update interface for the main timing loop.  
        // there are 64 samples.
        timebase_last_ms = 0; 
        timebase_interval_ms = ( sample_interval_minutes * 60 ) / pdp_count;  
        timebase_interval_ms *= 1000;

        timebase_err         = timebase_interval_ms / 2; 
    }

    function interp_ready() as Boolean {
        return ( pdp_sample_i >= pdp_count );
    }

    // Update the running timebase/iterpolator. 
    // return a 1 if its time to add a new sample.
    function interpolate(now as Number) as Boolean {
        var duration = now - timebase_last_ms;
        timebase_last_ms = now;

        timebase_err -= duration; // Use Bresenhams Algorithm.

        if ( timebase_err  <= 0 ) {
            timebase_err += timebase_interval_ms;
            return(true);
        }
        else {
            return(false);
        }
    }

    // Add a sample and return the new pace information.
    // When this is complete, pdp_sample_i points at the oldest 
    // data point, and pdp_sample_i-1 points to the newest.
    (:typecheck(false))
    function add_sample(tTime as Number, eDistance as Float, totAscent as Float) as Void {
        var i = pdp_sample_i & pdp_mask;

        data_timerTime      [i] = tTime;  
        data_elapsedDistance[i] = eDistance;
        data_totalAscent    [i] = totAscent;

        pdp_sample_i++;
    }

    // Call this every time.  If something changes, update wwpace.
    (:typecheck(false))
    function service(now as Number, tTime as Number, eDistance as Float, totAscent as Float) as Void
    {
        if ( !self.interpolate(now) ) {
            return;
        }
                
        self.add_sample(tTime, eDistance, totAscent);

        // Make sure that there is enough data.
        if ( pdp_sample_i < pdp_count ) {
            ww_pace = 0.0;
            return; 
        }

        var t0     =   pdp_sample_i       & pdp_mask; // Oldest.
        var t      = ( pdp_sample_i - 1 ) & pdp_mask; // Now.

        var time   = data_timerTime[t] - data_timerTime[t0];
        var dist   = data_elapsedDistance[t] - data_elapsedDistance[t0];
        var ascent = data_totalAscent[t] - data_totalAscent[t0];
        
        // Time should not equal zero.   This is a sanity check. 
        if ( time != 0 )     { ww_pace = analyze(time, dist, ascent); }
        else                 { ww_pace = 0.0; } 
    }
} // class MovingAverages

class WWPaceCalcV2View extends WatchUi.DataField {

    var Pace; // This gets displayed.

    var         interp = new Array<MovingAverage>[6];
    const method_names = ["WWPace", "Pace 1H", "Pace 2H", "Pace 4H", "Pace 8H", "24H"];

    // ------------------------------------
    // Display Logic.

    var   d_cycle      = 15; // Count this down to cycle the field. 
    const d_cycle_init = 15; // Reset Value. 

    var   d_index     = 0;  // Zero means 'Whole Ride'  Matches the labels.
    const d_index_max = 5;

    (:typecheck(false))
    function initialize() {
        DataField.initialize();

        System.println("Starting");
        
        interp[1] = new MovingAverage(  60); // 1
        interp[2] = new MovingAverage( 120); // 2
        interp[3] = new MovingAverage( 240); // 4
        interp[4] = new MovingAverage( 480); // 8
        interp[5] = new MovingAverage(1440); // 24
    }

    // ----------------------------------------
    // ----------------------------------------
    // Cycle the display.   Every d_cycle_init 
    // cycles, set d_index to the next value.
    (:typecheck(false))
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
        if ( d_index != 0 && !interp[d_index].interp_ready() ) {
            d_index = 0; 
            }

        // self.label = method_names[d_index];
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    (:typecheck(false))
    function compute(info as Activity.Info) as Void {

        next_display();

        // The interpolator has to run at all times, or 
        // it will get stuck and never recover. 
        // var now  = System.getTimer(); // This is free-running since device start.
        var now  = info.elapsedTime; // This is 0 until you start.

        // All hell breaks loose when now = 0, because divide by zero.
        if ( now == 0 ) { Pace = 0.0; return; }

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
        	return;			        
			}             

        // Otherwise, normalcy.    Feed the interpolators timertime.
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
            return;
            }

        // Select the data to display, based upon the current display_index.
        // Index 0 is reserved for 'Whole Ride'
        if ( d_index == 0 ) {
            // Note: Timertime is never 0, so no check required.
            Pace = analyze(info.timerTime, info.elapsedDistance, info.totalAscent);
            return;
        } else {
            Pace = interp[d_index].ww_pace;
            return; 
        }

    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var value = View.findDrawableById("value") as Text;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
        }
        value.setText(Pace.format("%2.2f"));

        (View.findDrawableById("label") as Text).setText(method_names[d_index]);

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
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
            var labelView = View.findDrawableById("label") as Text;
            labelView.locY = labelView.locY - 16;
            var valueView = View.findDrawableById("value") as Text;
            valueView.locY = valueView.locY + 7;
        }

        // (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
        (View.findDrawableById("label") as Text).setText(method_names[d_index]);

    }

}
