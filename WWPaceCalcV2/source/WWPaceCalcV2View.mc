import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// ---------------------------------------------------------------
// ---------------------------------------------------------------
// Primary data point collection.
// ---------------------------------------------------------------
// ---------------------------------------------------------------
const data_points_size = 64;  // ATTN! Must be 2^N
const data_points_mask = data_points_size - 1;  


// ---------------------------------------------------------------
// ---------------------------------------------------------------
// Do the numerics 
// ---------------------------------------------------------------
// ---------------------------------------------------------------
function analyze(timerTime, elapsedDistance, totalAscent) as Float {

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


class WWPaceCalcV2View extends WatchUi.DataField {

    hidden var mValue as Numeric;

    function initialize() {
        DataField.initialize();
        mValue = 0.0f;
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

        (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
        if(info has :currentHeartRate){
            if(info.currentHeartRate != null){
                mValue = info.currentHeartRate as Number;
            } else {
                mValue = 0.0f;
            }
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
        value.setText(mValue.format("%.2f"));

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
