import Toybox.Lang;
import Toybox.WatchUi; // for Text

import Toybox.Test;

class RandoCalcEngine
{

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
    const luts as Array = [
        acp_90_lut,
        pbp_90_lut,
        pbp_84_lut, 
        pbp_80_lut, 
        straight_90_lut, 
        rusa_lut, 
        lel125_lut 
        ];

    // Displayable table names.
    const method_names = ["ACP90", "PBP90", "PBP84", "PBP80", "RM90" , "RUSA", "LEL128" ];

    // --------------------------------------------------------------
    // --------------------------------------------------------------
    // --------------------------------------------------------------
    // --------------------------------------------------------------
    // --------------------------------------------------------------
    // --------------------------------------------------------------
    public var BankedTime     as Float; // Final calulated value.
    public var method_name    as Text;

    // --------------------------------------------------------------
    // Internal State.
    // --------------------------------------------------------------

    protected var table_entry as Number;
    protected var lut         as Array<Array>;

    public function initialize( which_flavor ) {
        BankedTime        = 0.0f;
        table_entry       = 0;

        // ------------------------------------------
        // Choose the look-up table. 
        // ------------------------------------------
        if (which_flavor >= method_names.size() ) {
            which_flavor = 0; // On fail, log and recover;
            System.println("Programmer error.  Invalid table");
        }

        method_name       = method_names[which_flavor];   

        // Todo.  Add error checking here.  

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
    }

    // Run the update.  Note that elapsed minutes 
    // is a high-level construct.
    public function update( distance, elapsed_mins ) {
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

        var closetime_mins = base_mins + leg_minutes_allowed;
        
        self.BankedTime = (closetime_mins - elapsed_mins);
    }

}



    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------

// Unit Testing. 

(:test)
function EngineInitNormal(logger as Logger) as Boolean {
    var engine = new RandoCalcEngine(0);


    logger.debug("UnitTestInitNormal.  method_name =" + engine.method_name );
    return( engine.method_name.equals("ACP90") );
}

(:test)
function EngineInitBad(logger as Logger) as Boolean {
    var engine = new RandoCalcEngine(57);

    logger.debug("UnitTestInitNormal.  method_name =" + engine.method_name );
    return( engine.method_name.equals("ACP90") );
}

