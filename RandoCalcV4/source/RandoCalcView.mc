import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

import Toybox.Test;


class RandoCalcV2View extends WatchUi.DataField {

    const do_simulate = 0;

    // -------------------------------------------------------------
    // Support methods 
    // -------------------------------------------------------------
    function format_time(banked as Float, verbose_cutoff as Float, verbose as Boolean) as String {
        var formatted; 

        // ---------------- Seconds ----------------
        // XXs 
        
        if ( banked < 1.0 ) { // Seconds
            var seconds = banked * 60.0f;
            seconds = seconds.toNumber(); // Round to an integer.
            formatted = seconds.format("%d") + "s";
            return(formatted);
            }
        // ---------------- Up to 60 / 90 Minutes ----------------
        // XXmSS
        if ( banked < verbose_cutoff ) { // Minutes and seconds.
            var m = banked.toNumber();
            var s = ( banked - m ) * 60.0f;
            s = s.toNumber();
            
            formatted = m.format("%d") + "m" + s.format("%02d");  	
            return(formatted);
            }

        // ---------------- Beyond 60 or 90m ----------------------------
        // The Math is the same for HmMM.M and HHmMM, so do it together.
        var b_hours = banked * ( 0.0166666666666666666666666f ); // divide by 60
        
        var h = b_hours.toNumber();
        var m = banked - (h * 60.0f); // back to minutes with fractional minutes.

        // ---------------- Up to 10 Hours ----------------
        // XhYY.Z 
        if ( verbose && banked < 600.0 ) {
            // Bizarreness.   You can't do leading zeros and fractions. C
            // seems to behave the same way.
            if ( m < 10.0 ) {
                formatted = h.format("%d") + "h0" +  m.format("%2.1f");
            }
            else {
                formatted = h.format("%d") + "h" +  m.format("%2.1f");  				
            }  

            return(formatted);
            }

        // ---------------- Over 10 Hours ----------------
        // XXhMM
        // System.println("m +" + m);
        m = m.toNumber();
        formatted = h.format("%d") + "h" + m.format("%02d");
        return(formatted);
    }

    // -------------------------------------------------------------------------
    // Main Logic 
    // -------------------------------------------------------------------------

    hidden var verbose         as Boolean; 
    hidden var verbose_cutoff  as Float ;

    private var trend  as RandoCalcTrend; 
    private var engine as RandoCalcEngine;

    private var _late_message as String;

    // Set the label of the data field here.
    function initialize() {
        DataField.initialize();

        trend = new RandoCalcTrend();

        // Localization.
        _late_message = WatchUi.loadResource($.Rez.Strings.late) as String;

        // ------------------------------------------
        // Display Format/Verbosity.
        // ------------------------------------------
        verbose           = Application.Properties.getValue("ui_verbose");
        if ( verbose ) { verbose_cutoff = 90.0; }
        else           { verbose_cutoff = 60.0; } 

        // ------------------------------------------
        // Choose the look-up table. 
        // ------------------------------------------
        var which_flavor      = Application.Properties.getValue("method");
        engine = new RandoCalcEngine(which_flavor);
       
        // ------------------------------------------
        // Simulation Init.
        // ------------------------------------------
        if ( do_simulate ) {
            simulated_distance = 0.0;
            simulation_counter  = 0;

            System.println("Started 0kph");
        }
    }

    function onSettingsChanged() {
        trend = new RandoCalcTrend();

        // Localization.
        _late_message = WatchUi.loadResource($.Rez.Strings.late) as String;

        // ------------------------------------------
        // Display Format/Verbosity.
        // ------------------------------------------
        verbose           = Application.Properties.getValue("ui_verbose");
        if ( verbose ) { verbose_cutoff = 90.0; }
        else           { verbose_cutoff = 60.0; } 

        // ------------------------------------------
        // Choose the look-up table. 
        // ------------------------------------------
        var which_flavor      = Application.Properties.getValue("method");
        engine = new RandoCalcEngine(which_flavor);
       
    }

    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
    function compute(info) as Void {

        var distance;
        if ( do_simulate ) {
            simulate();
            distance = simulated_distance;	
        } else {
            distance = info.elapsedDistance;	
        }

        if ( distance == null || info.elapsedTime == null ) {
            engine.BankedTime = 0.0f;
            return;
            }

        var elapsed_mins;

        if ( do_simulate != 1 ) { 
            elapsed_mins = (info.elapsedTime * .0000166666 );
        }	
        else { 
            elapsed_mins = simulation_counter;
            // System.println( "dist: " + distance + " mins: " + elapsed_mins);
        }

        engine.update(distance, elapsed_mins);

        // ---------------------------------------------------------------
        // Trend Calculation for Mario Claussnitzer.
        // Save the current current banked value. 
        // If you have more banked time than you did 30s ago, its a positive trend.
        trend.update(engine.BankedTime);

        return; 
    }
 
    // --------------------------------------------------------------
    // --------------------------------------------------------------
    // Layout  
    // --------------------------------------------------------------
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
            var labelView = View.findDrawableById("label") as WatchUi.Text;

            labelView.locY = labelView.locY - 16;
            var valueView = View.findDrawableById("value") as WatchUi.Text;

            valueView.locY = valueView.locY + 7;
        }

        View.findDrawableById("label").setText(engine.method_name);
        return;
    }

    // -------------------------------------------------------------------
    // -------------------------------------------------------------------
    // This will be called
    // once a second when the data field is visible.
    // Make a local copy of the Calculated value because the 
    // two routines run asyncronously.   This is probably not a hazard,
    // but better to be safe.
    // -------------------------------------------------------------------
    // -------------------------------------------------------------------
    function onUpdate(dc) {

        var inthehole; 
        var banked;
        var formatted;
        
        // First order of business.  Positive or negative?
        if ( engine.BankedTime < 0 ) {
            inthehole = true;
            banked = engine.BankedTime.abs();
            }
        else {
            inthehole = false;
            banked = engine.BankedTime;
            }

        formatted = format_time(banked, verbose_cutoff, verbose);
        
        // Add the trend indicator.
        formatted = formatted + trend.trend_text;
                        
        var obscurityFlags = DataField.getObscurityFlags();

        // --------------------------------------------------------
        // Layout code from the reference apps
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
            var labelView = View.findDrawableById("label"); // as Text;
            labelView.locY = labelView.locY - 16;
            var valueView = View.findDrawableById("value"); // as Text;
            valueView.locY = valueView.locY + 7;
        }

        var paint_white = ( getBackgroundColor() == Graphics.COLOR_WHITE );

        // If in the hole, flip it... 
        if ( inthehole ) { paint_white = !paint_white; } 

        var label = View.findDrawableById("label") as Text;
        var value = View.findDrawableById("value") as Text;
        var bg    = View.findDrawableById("Background") as Text;

        if ( paint_white ) {
            bg.setColor(Graphics.COLOR_WHITE);            
            label.setColor(Graphics.COLOR_BLACK);	
            value.setColor(Graphics.COLOR_BLACK);
        } else {
            bg.setColor(Graphics.COLOR_BLACK);
            label.setColor(Graphics.COLOR_WHITE);
            value.setColor(Graphics.COLOR_WHITE); 			
        }

        // August 2023- Make a shorter labels for watches.
        // View.findDrawableById("label").setText("Late " + method_name);

        if ( inthehole )  { label.setText(_late_message); }
        else              { label.setText(engine.method_name);   }
 
        value.setText(formatted);

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }


    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
    // Simulation for display format verification.
    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
    // Generate a monotonic counter that triggers the different 
    // display formats.   Do this with simulated distance. 
    // 30 kph = 30000 m / 3600 s = 8.333 m/s

    // General Plan:
    // Start, 0 kph for 30s
    // 30 kph for 30s 

    const simspeed15 = 250.0;  // 15kph = 250 m/minute.

    hidden var simulated_distance as Float  = 0.0;  // Meters 
    hidden var simulated_speed    as Float  = 0.0;  // Meters/s
    hidden var simulation_counter as Number = 0;    // Minutes

    function simulate() as Void {

        if ( do_simulate != 1 ) { return; } 

        switch(simulation_counter) {
            case 0:  // Count down from 0 to -10m
                System.println("Sim 0 kph c = 0");
                simulated_speed = 0.0;
                break;  
            case 10:  // Hold pretty steady 
                System.println("Sim 15kph @ c = 15");
                simulated_speed = simspeed15;
                break;
            case 30:  
                System.println("Sim 60kph @ c = 30");
                simulated_speed = simspeed15 * 4.0;
                break;
            case 90:
                System.println("Sim 30kph @c = 90 Distance = 22.5km");
                simulated_distance = simulated_distance + 1.445 * 15000;
                break;
            case 120:
                System.println("Distance = 150km c = 240");
                simulated_distance = simulated_distance + 8.38 * 15000;
            default:
                simulated_distance = simulated_distance + simulated_speed;
        }

        simulation_counter++;
        System.print(".");
    }
    
}

// -----------------------------------------------------------------
// -----------------------------------------------------------------
// Unit tests for the formatter
// -----------------------------------------------------------------
// -----------------------------------------------------------------
(:test)
function FormatterTest(logger as Logger) as Boolean {

    var view = new RandoCalcV2View(); 

    var vc = 60.0; 
    var verb = false;
    var output = "";

    logger.debug( "---------------------------" );
    logger.debug( "FT Basic Tests, Non-Verbose" );
    logger.debug( "---------------------------" );

    output = view.format_time(0.0, vc, verb);
    logger.debug( "0s : " + output );
    Test.assert(output.equals("0s"));

    output = view.format_time(0.5, vc, verb);
    logger.debug( "30s : " + output );
    Test.assert(output.equals("30s"));

    output = view.format_time(1.5, vc, verb);
    logger.debug( "90s: " + output );
    Test.assert(output.equals("1m30"));

    output = view.format_time(20.0, vc, verb);
    logger.debug( "20 min: " + output );
    Test.assert(output.equals("20m00"));

    logger.debug( "---------------------------" );
    logger.debug( "FT Cutoff Tests, Non-Verbose" );
    logger.debug( "---------------------------" );

    // Verbosity Cutoff.    For purely personal reasons 
    // I prefer 89m00 over 1h29m 
    vc = 90.0; 
    output = view.format_time(80, vc, verb);
    logger.debug( "80 min, vc 90:" + output );
    Test.assert(output.equals("80m00"));

    vc = 60.0; 
    output = view.format_time(80.0, vc, verb);
    logger.debug( "80 min, vc 60: " + output );
    Test.assert(output.equals("1h20"));

    logger.debug( "---------------------------" );
    logger.debug( "Up to 10h" );
    logger.debug( "---------------------------" );
 
    output = view.format_time(185.0, vc, false);
    logger.debug( "3h5mins verbose=false : " + output );
    Test.assert(output.equals("3h05"));

    output = view.format_time(195.0, vc, false);
    logger.debug( "3h15mins verbose=false : " + output );
    Test.assert(output.equals("3h15"));


    output = view.format_time(185.0, vc, true);
    logger.debug( "3h5mins verbose=true : " + output );
    Test.assert(output.equals("3h05.0"));

    output = view.format_time(195.2, vc, true);
    logger.debug( "3h5mins verbose=true : " + output );
    Test.assert(output.equals("3h15.2"));

    logger.debug( "---------------------------" );
    logger.debug( "Over 10h" );
    logger.debug( "---------------------------" );

    output = view.format_time(601.0, vc, false);
    logger.debug( "10h01mins verbose=false : " + output );
    Test.assert(output.equals("10h01"));


    // Over 10 Hours


    // function format_time(banked as Float, verbose_cutoff as Float, verbose as Boolean) as String
    return(true);

}