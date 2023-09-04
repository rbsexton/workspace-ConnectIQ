import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class RandoCalcV2View extends WatchUi.DataField {

    const do_simulate = 0;

    // -------------------------------------------------------------------------
    // Look up tables.
    // -------------------------------------------------------------------------

    // Distance (km), Hours Offset
    //
    // The internal units are meters, minutes, and minutes/meter.
    // the first step is converting from human friendly units to something 
    // that works better for calculation. 

    // These tables are copied to make the internal lookup table. 
    // 
    // That table contains:
    // starting km for this leg 
    // time limit for this leg. 
    // minimum speed during this leg, in minutes/meter. 
    // minimum speed during this leg in kph. 
    
    // This is an embedded device, so its better to do any complex math 
    // up front rather than in real time. 
 
    // There is an assumption that the last leg has the same minimum 
    // speed as the second-to last leg.   Thats not true in some 
    // cases, such as kms 1000-1200, where the pace actually picks 
    // up after the more relaxed time requirements.  
    // in that case, add another entry that has the required speed. 



    // -------------------------------------------------------------
    // ACP Qualifiers
    // -------------------------------------------------------------

    // Note:  There is bonus time built in due to rounding
    // up the time limits per ACP. 
    // For a 200k and 400k, you get additional time ( 10m and 20m, respectively )
    // The Calculator doesn't know what event you are riding.
    // 
    // There is no such thing as an ACP-sanctioned 1200, but define it 
    // so that the required minimum speed goes back up when you hit 1000km.
    const acp_90_lut = [
        [    0,     0 ],
        [  200,  13.5 ], // 200k in 13.5h 
        [  300,  20.0 ], // 100k in  7.5h
        [  400,  27.0 ], // 100k in    7h 		
        [  600,  40.0 ], // 200k in   13h 		
        [ 1000,  75.0 ], // 400k in   35h		
        [ 1200,  90.0 ], // 200k in   15h
        [    0,     0 ] // Mark the end of the list.
    ];

    // -------------------------------------------------------------
    // PBP
    // Raw PBP data in a google sheet:
    // https://docs.google.com/spreadsheets/d/1jlxB4iT0GtjdmqXfRqaqDyj7bTXQCDimbuHuwPGiApo/edit?usp=sharing
    // -------------------------------------------------------------

    /* PBP 2023 */ 
    const pbp_90_lut = [
        [ 0,           0 ],
        [ 119,   7.96667 ],
        [ 203,  13.48333 ],
        [ 292,  19.43333 ],
        [ 353,  23.51667 ],
        [ 378,  25.25000 ],
        [ 435,  29.06667 ],
        [ 482,  32.16667 ],
        [ 514,  34.30000 ],
        [ 604,  40.31667 ],
        [ 697,  48.06667 ],
        [ 731,  50.78333 ],
        [ 782,  55.16667 ],
        [ 842,  59.81667 ],
        [ 867,  61.75000 ],
        [ 928,  66.41667 ],
        [ 1017, 73.35000 ],
        [ 1099, 80.11667 ],
        [ 1176, 86.53333 ],
        [ 1219, 90.00000 ], 
        [    0,        0 ] // Mark the end of the list.
    ];

    // 2023 
    const pbp_84_lut = [
        [    0,  0.00000 ],
        [  119,  7.23333 ],
        [  203, 12.40000 ],
        [  292, 17.98333 ],
        [  353, 21.80000 ],
        [  378, 23.43333 ],
        [  435, 27.01667 ],
        [  482, 30.10000 ],
        [  514, 32.23333 ],
        [  604, 38.25000 ],
        [  697, 44.90000 ],
        [  731, 47.23333 ],
        [  782, 50.98333 ],
        [  842, 55.31667 ],
        [  867, 57.10000 ],
        [  928, 61.43333 ],
        [ 1017, 67.83333 ],
        [ 1099, 74.10000 ],
        [ 1176, 80.51667 ],
        [ 1219, 84.00000 ],
        [    0,        0 ] 
    ];

    // 2019 
    const pbp_80_lut = [
        [   0,  0.0000 ],
        [ 119,  7.0333 ],
        [ 203, 11.8833 ],
        [ 292, 17.1500 ],
        [ 353, 20.7500 ],
        [ 378, 22.2667 ],
        [ 435, 25.6500 ],
        [ 482, 28.3833 ],
        [ 514, 30.5500 ],
        [ 604, 36.1833 ],
        [ 697, 42.8000 ],
        [ 731, 45.1167 ],
        [ 782, 48.8833 ],
        [ 842, 53.2000 ],
        [ 867, 55.0000 ],
        [ 928, 59.3333 ],
        [1017, 65.7333 ],
        [1099, 71.5333 ],
        [1176, 77.0333 ],
        [1219, 80.0000 ],
        [   0,       0 ] 
    ];

    // -------------------------------------------------------------
    // Straight Time, eg: SIR events.
    // -------------------------------------------------------------
    const straight_90_lut = [ // (90*60) / 1200000 
        [    0,    0 ],
        [ 1200, 90.0 ], 
        [    0,    0 ],
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
        [    0,         0 ], 
        [  700,  46.66667 ], //  46:40
        [ 1300,  97.75000 ], //  97:45
        [ 1900, 158.33332 ], // 158:20		
        [ 2500, 300.00000 ], // 300:00 	
        [ 2700, 324.00000 ], // Over-run entry.  	
        [    0,         0 ]  
        ];

    // -------------------------------------------------------------
    // LEL
    // -------------------------------------------------------------

    // LEL 125h Rules.   Straight time, 1520km in 125h
    // LEL 2022 Final, with route changes 2022-07-31.   1520km in 125h 
    const lel125_lut = [
        // [ 0, 0, 0.004934210526316 ], // 1520km in 125h
        // [ 0, 0, 0.00487012987013  ], // 1540km in 125h 
        [    0,       0 ], // 1540km in 128.333h = 12kph
        [ 1540, 128.333 ], // 300:00 	
        [    0,       0 ] 
        ];

    // -------------------------------------------------------------
    // Tables of tables.
    // -------------------------------------------------------------

    // These lists will be indexed by the user config settings.
    const luts as Array = [acp_90_lut, pbp_90_lut, pbp_84_lut, pbp_80_lut, straight_90_lut , rusa_lut, lel125_lut ];

    // Displayable table names.
    const method_names = ["ACP90", "PBP90", "PBP84", "PBP80", "RM90" , "RUSA", "LEL128" ];

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
            formatted = h.format("%d") + "h" +  m.format("%02.1f");  				
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

    hidden var BankedTime     as Float; // Final calulated value.
    hidden var PreviousBanked as Float;
        
    hidden var table_entry    as Number;

    hidden var which_flavor;
    var        method_name    as Text;

    hidden var verbose         as Boolean; 
    hidden var verbose_cutoff  as Float ;

    var        lut as Array<Array>;

    var        trend_data_banked as Array<Float> = new[31];
    hidden var trend_i     as Number;
    hidden var trend_text  as String;

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

        var base_lut      = luts[which_flavor] as Array<Array>;
        var base_lut_len  = luts[which_flavor].size();

        // From the web example.

        lut = new [ base_lut_len ];

        // Initialize the sub-arrays.
        // NOTE! This code looks at 'next', and counts upon their 
        // being an over-run/mark the end entry.   
        for( var i = 0; i < (base_lut_len-1); i += 1 ) {
            lut[i] = new Array<Float>[ 4 ];

            lut[i][0] = base_lut[i][0] * 1000.0;          // km to meters.  API Uses floats.
            lut[i][1] = base_lut[i][1] * 60.0;            // Hours to minutes.

            // Calculate the expected speed in minutes/meter.
            // Its the length of this leg divided by the minutes between legs. 
            //
            // The special case is the last entry, where we just assume that the 
            // last speed is correct. 
            // 
        
            var leg_km = base_lut[i+1][0] - base_lut[i][0];
            if ( leg_km < 0 ) {
                lut[i][2] = lut[i-1][2];  // Re-use the last one.
                lut[i][3] = lut[i-1][3];  // Re-use the last one.
            } else {
                var leg_hours = base_lut[i+1][1] - base_lut[i][1];
                var leg_kph   = leg_km / leg_hours; 

                lut[i][2] = (60.0 / leg_kph ) / 1000.0; // kph to minutes/meter 
                lut[i][3] = leg_kph; 
            }
        }
        // Create the entry to detect 'end of table'
        {
            var last = base_lut_len - 1; 
            lut[last]    = new [ 4 ];
            lut[last][0] = 0.0;
            lut[last][1] = 0.0;
            lut[last][2] = 0.0;
            lut[last][3] = 0.0;
        }
       
        // ------------------------------------------
        // Simulation Init.
        // ------------------------------------------
        simulated_distance = 0.0;
        simulation_counter  = 0;

        System.println("Started 0kph");
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

        View.findDrawableById("label").setText(Rez.Strings.label);
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
        if ( BankedTime < 0 ) {
            inthehole = true;
            banked = BankedTime.abs();
            }
        else {
            inthehole = false;
            banked = BankedTime;
            }

        formatted = format_time(banked, verbose_cutoff, verbose);
        
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

        var paint_white = ( getBackgroundColor() == Graphics.COLOR_WHITE );

        // If in the hole, flip it... 
        if ( inthehole ) {
            if ( paint_white ) { paint_white = false; } 
            else               { paint_white = true ; }
        }

        if ( paint_white ) {
            View.findDrawableById("Background").setColor(Graphics.COLOR_WHITE);            
            View.findDrawableById("label").setColor(Graphics.COLOR_BLACK);	
            View.findDrawableById("value").setColor(Graphics.COLOR_BLACK);
        } else {
            View.findDrawableById("Background").setColor(Graphics.COLOR_BLACK);
            View.findDrawableById("label").setColor(Graphics.COLOR_WHITE);
            View.findDrawableById("value").setColor(Graphics.COLOR_WHITE); 			
        }

        // August 2023- Make a shorter labels for watches.
        // View.findDrawableById("label").setText("Late " + method_name);

        if ( inthehole )  { View.findDrawableById("label").setText(_late_message); }
        else              { View.findDrawableById("label").setText(method_name);   }
 
        View.findDrawableById("value").setText(formatted);

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
