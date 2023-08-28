using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;

import Toybox.Lang;

class RandoCalcV2View extends WatchUi.DataField {

    const do_simulate = 0;

    // -------------------------------------------------------------------------
    // Look up tables.
    // -------------------------------------------------------------------------

    // Distance (km), Hours Offset, kph for this leg.
    //
    // The internal units are meters, minutes, and minutes/meter.
    // the first step is converting from human friendly units to something 
    // that works better for calculation. 

    // a bit unwieldy when the natural unit for the end user is 
    // minutes, so the first step is conversion to minutes. 
    // This is an embedded device, so its better to do any complex math 
    // up front rather than in real time. 
    //

    // -------------------------------------------------------------
    // ACP Qualifiers
    // -------------------------------------------------------------

    // Note:   This table looks a little funny because there is bonus
    // time built in due to rounding up the time limits per ACP. 
    // For a 200k and 400k, you get additional time ( 10m and 20m, respectively )

    const acp_90_lut = [
        [    0,     0, 14.814814814814815 ],
        [  200,  13.5, 15.384615384615385 ],
        [  300,  20.0, 14.285714285714286 ],
        [  400,  27.0, 15.384615384615385 ],		
        [  600,  40.0, 11.428571428571429 ],		
        [ 1000,  75.0, 13.300000576333358 ],		
        [ 0, 0, 0 ] // Mark the end of the list.
    ];

    // -------------------------------------------------------------
    // PBP
    // Raw PBP data in a google sheet:
    // https://docs.google.com/spreadsheets/d/1jlxB4iT0GtjdmqXfRqaqDyj7bTXQCDimbuHuwPGiApo/edit?usp=sharing
    // -------------------------------------------------------------

    /* PBP 2023 */ 
    const pbp_90_lut = [
        [ 0,           0, 14.93724 ],
        [ 119,   7.96667, 14.93724 ],
        [ 203,  13.48333, 15.22659 ],
        [ 292,  19.43333, 14.95798 ],
        [ 353,  23.51667, 14.93878 ],
        [ 378,  25.25000, 14.42308 ],
        [ 435,  29.06667, 14.93450 ],
        [ 482,  32.16667, 15.16129 ],
        [ 514,  34.30000, 15.00000 ],
        [ 604,  40.31667, 14.95845 ],
        [ 697,  48.06667, 12.00000 ],
        [ 731,  50.78333, 12.51534 ],
        [ 782,  55.16667, 11.63498 ],
        [ 842,  59.81667, 12.90323 ],
        [ 867,  61.75000, 12.91139 ],
        [ 928,  66.41667, 13.07143 ],
        [ 1017, 73.35000, 12.83654 ],
        [ 1099, 80.11667, 12.11823 ],
        [ 1176, 86.53333, 12.00000 ],
        [ 1219, 90.00000, 12.40385 ], 
        [ 0, 0, 0 ] // Mark the end of the list.
    ];

    // 2023 
    const pbp_84_lut = [
    [    0,  0.00000,  16.45161 ],
    [  119,  7.23333,  16.45161 ],
    [  203, 12.40000,  16.25806 ],
    [  292, 17.98333,  15.94030 ],
    [  353, 21.80000,  15.98253 ],
    [  378, 23.43333,  15.30612 ],
    [  435, 27.01667,  15.90698 ],
    [  482, 30.10000,  15.24324 ],
    [  514, 32.23333,  15.00000 ],
    [  604, 38.25000,  14.95845 ],
    [  697, 44.90000,  13.98496 ],
    [  731, 47.23333,  14.57143 ],
    [  782, 50.98333,  13.60000 ],
    [  842, 55.31667,  13.84615 ],
    [  867, 57.10000,  13.89646 ],
    [  928, 61.43333,  14.07692 ],
    [ 1017, 67.83333,  13.90625 ],
    [ 1099, 74.10000,  13.08511 ],
    [ 1176, 80.51667,  12.00000 ],
    [ 1219, 84.00000,  12.34450 ],
    [ 0, 0, 0 ] 
    ];

    // 2019 
    const pbp_80_lut = [
    [   0,  0.0000, 16.9194 ],
    [ 119,  7.0333, 16.9194 ],
    [ 203, 11.8833, 17.3196 ],
    [ 292, 17.1500, 16.8987 ],
    [ 353, 20.7500, 16.9444 ],
    [ 378, 22.2667, 16.4835 ],
    [ 435, 25.6500, 16.8473 ],
    [ 482, 28.3833, 17.1951 ],
    [ 514, 30.5500, 14.7692 ],
    [ 604, 36.1833, 15.9763 ],
    [ 697, 42.8000, 14.0554 ],
    [ 731, 45.1167, 14.6763 ],
    [ 782, 48.8833, 13.5398 ],
    [ 842, 53.2000, 13.8996 ],
    [ 867, 55.0000, 13.8965 ],
    [ 928, 59.3333, 14.0769 ],
    [1017, 65.7333, 13.9063 ],
    [1099, 71.5333, 14.1379 ],
    [1176, 77.0333, 14.0000 ],
    [1219, 80.0000, 14.4944 ],
    [ 0, 0, 0 ] 
    ];

    // -------------------------------------------------------------
    // Straight Time, eg: SIR events.
    // -------------------------------------------------------------
    const straight_90_lut = [ // (90*60) / 1200000 
    [ 0, 0, 13.33333 ],
    [ 0, 0,        0 ] 
    ];

    // -------------------------------------------------------------
    // RUSA Permanents. 
    // -------------------------------------------------------------

    // Table from https://rusa.org/octime_perm.html
    //    0-699 15kph 
    //  700-1299 13.3 kph
    // 1300-1890 12kph 
    // 1900-2499 10kph 
    // 2500+     200km/day 
    const rusa_lut = [
        [       0,      0, 15.000000 ], 
        [  700,  46.66667, 13.300000 ], //  46:40
        [ 1300,  97.75000, 12.000000 ], //  97:45
        [ 1900, 158.33332, 10.000000 ], // 158:20		
        [ 2500, 300.00000,  8.333333 ], // 300:00 	
        [ 0, 0, 0 ] 
        ];

    // -------------------------------------------------------------
    // LEL
    // -------------------------------------------------------------

    // LEL 125h Rules.   Straight time, 1520km in 125h
    // LEL 2022 Final, with route changes 2022-07-31.   1520km in 125h 
    const lel125_lut = [
        // [ 0, 0, 0.004934210526316 ], // 1520km in 125h
        // [ 0, 0, 0.00487012987013  ], // 1540km in 125h 
            [ 0, 0, 12.0000000000000  ], // 1540km in 128.333h = 12kph
            [ 0, 0, 0 ] 
        ];

    // -------------------------------------------------------------
    // Tables of tables.
    // -------------------------------------------------------------

    // These lists will be indexed by the user config settings.
    const luts = [acp_90_lut, pbp_90_lut, pbp_84_lut, pbp_80_lut, straight_90_lut , rusa_lut, lel125_lut ];

    // Displayable table names.
    const method_names = ["ACP90", "PBP90", "PBP84", "PBP80", "RM90" , "RUSA", "LEL128" ];

    // -------------------------------------------------------------------------
    // Main Logic 
    // -------------------------------------------------------------------------

    hidden var BankedTime; // Final calulated value.
    hidden var mValueLast; //
    hidden var PreviousBanked;
        
    hidden var table_entry;

    hidden var which_flavor;
    var        method_name;

    hidden var verbose; 
    hidden var verbose_cutoff;

    var        lut as Array;

    var        trend_data_banked as Array<Float> = new[31];
    hidden var trend_i;
    hidden var trend_text;

    private var _late_message as String;

    // Set the label of the data field here.
    function initialize() {
        DataField.initialize();

        // Localization.
        _late_message = WatchUi.loadResource($.Rez.Strings.late) as String;

        // ------------------------------------------
        // Progress indicator.
        // ------------------------------------------
        BankedTime        = 0.0f;
        PreviousBanked    = 0.0f;
        table_entry       = 0;

        for( var i = 0; i < trend_data_banked.size(); i++ ) {
            trend_data_banked[i]  = 0.0; 
        }

        trend_i           = 0;
        trend_text        = "";

        // ------------------------------------------
        // Display Format/Verbosity.
        // ------------------------------------------
        verbose           = Application.Properties.getValue("ui_verbose");
        if ( verbose ) { verbose_cutoff = 90.0; }
        else           { verbose_cutoff = 60.0; } 

        // ------------------------------------------
        // Choose the look-up table. 
        // ------------------------------------------
        which_flavor      = Application.Properties.getValue("method");
        method_name       = method_names[which_flavor];     

        var base_lut      = luts[which_flavor];
        var base_lut_len  = luts[which_flavor].size();

        // From the web example.

        lut = new [ base_lut_len ];

        // Initialize the sub-arrays
        for( var i = 0; i < base_lut_len; i += 1 ) {
            lut[i] = new [ 3 ];

            lut[i][0] = base_lut[i][0] * 1000.0;          // km to meters.  API Uses floats.
            lut[i][1] = base_lut[i][1] * 60.0;            // Hours to minutes.

            // Calculate the expected speed in minutes/meter.
            // Its the length of this leg divided by the minutes a
            if ( base_lut[i][2] != 0 ) {
                lut[i][2] = (60.0 / base_lut[i][2]) / 1000.0; // kph to minutes/meter 
            } else {
                lut[i][2] = 0.0;
            }

        }

        // ------------------------------------------
        // Simulation Init.
        // ------------------------------------------
        simulated_distance = 0.0;
        simulation_counter  = 0;

        System.println("Started 0kph");
        }

    // Generate a monotonic counter that triggers the different 
    // display formats.   Do this with simulated distance. 
    // 30 kph = 30000 m / 3600 s = 8.333 m/s

    // General Plan:
    // Start, 0 kph for 30s
    // 30 kph for 30s 

    const simspeed15 = 250.0;  // 15kph = 250 m/minute.

    hidden var simulated_distance = 0.0;  // Meters 
    hidden var simulated_speed    = 0.0;  // Meters/s
    hidden var simulation_counter = 0;    // Minutes

    function simulate() {

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
                
    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
    function compute(info) {

        var distance;
        if ( do_simulate ) {
            simulate();
            distance = simulated_distance;	
        } else {
            distance = info.elapsedDistance;	
        }

        if ( distance == null || info.elapsedTime == null ) {
            BankedTime = 0.0f;
            return;
            }

        var closetime_mins;
        var elapsed_mins;

        if ( do_simulate != 1 ) { 
            elapsed_mins = (info.elapsedTime * .0000166666 );
        }	
        else { 
            elapsed_mins = simulation_counter;

            // System.println( "dist: " + distance + " mins: " + elapsed_mins);
        }
        
        // Figure out which entry.
        // Simplify this to a check for the next one.
        var i = table_entry + 1;
        
        // If the next entry is less than the distance so far
        // and the next entry isn't zero, use that one.
        if ( lut[i][0] != 0 && distance > lut[i][0] ) {
                table_entry = i; // Save state!
                }
        else { i = table_entry; }
        
        // Now we've ID'd the table entry to use.
        var base_mins  = lut[i][1];
        var leg_ridden = distance - lut[i][0];
        var leg_minutes_allowed = leg_ridden * lut[i][2];
        
        closetime_mins = base_mins + leg_minutes_allowed;
        
        BankedTime = (closetime_mins - elapsed_mins);

        // ---------------------------------------------------------------
        // Trend Calculation for Mario Claussnitzer.
        // Save the current current banked value. 
        // If you have more banked time than you did 30s ago, its a positive trend.
        {
            var trend_banked  = BankedTime   - trend_data_banked[trend_i];

            // System.print  ("tBanked " + trend_banked + ");

            if ( trend_banked > 0 ) {
                trend_text = "+";
                }
            else { 
                trend_text = " ";
                }

            trend_data_banked[trend_i]  = BankedTime;

            if ( trend_i < 30 ) { trend_i++; }
            else                { trend_i = 0; }
        }

        return; 
    }
 
    // --------------------------------------------------------------
    // Layout  
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

        View.findDrawableById("label").setText(Rez.Strings.label);
        return;
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

        // System.println(banked);

        // Format it according to magnitude.
        // Real world tests show that there are at most 4 usable digits  
        // on a 530, with 10 fields on the screen.
        
        // ---------------- Seconds ----------------
        // XXs 
        
        if ( banked < 1.0 ) { // Seconds
            var seconds = banked * 60.0f;
            seconds = seconds.toNumber(); // Round to an integer.
            formatted = seconds.format("%d") + "s";
            }
        // ---------------- Up to 60 / 90 Minutes ----------------
        // XXmSS
        else if ( banked < verbose_cutoff ) { // Minutes and seconds.
            var m = banked.toNumber();
            var s = ( banked - m ) * 60.0f;
            s = s.toNumber();
            
            formatted = m.format("%d") + "m" + s.format("%02d");  	
            }

        // ---------------- Beyond 60 or 90m ----------------------------
        // The Math is the same for HmMM.M and HHmMM, so do it together.
        else {
            var b_hours = banked * ( 0.0166666666666666666666666f ); // divide by 60
            
            var h = b_hours.toNumber();
            var m = banked - (h * 60.0f); // back to minutes with fractional minutes.

            // ---------------- Up to 10 Hours ----------------
            // XhYY.Z 
            if ( verbose && banked < 600.0 ) {
                formatted = h.format("%d") + "h" +  m.format("%02.1f");  				
                }

            // ---------------- Over 10 Hours ----------------
            // XXhMM
            else {			
                // System.println("m +" + m);
                m = m.toNumber();
                formatted = h.format("%d") + "h" + m.format("%02d");  				
                }
            }

        // Add the trend indicator.
        formatted = formatted + trend_text;
                        
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

            // August 2023- Make a shorter label for watches.
            // View.findDrawableById("label").setText("Late " + method_name);
            View.findDrawableById("label").setText(_late_message);
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
            
            // V3, August 2023 - A more concise label for use with watches. 
            // View.findDrawableById("label").setText("Banked " + method_name);
            View.findDrawableById("label").setText(method_name);
            }   

        View.findDrawableById("value").setText(formatted);

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
