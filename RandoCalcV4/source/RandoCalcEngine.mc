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

    // These tables are actually templates.   They're used 
    // to create the primary tables in GPS-friendly units.
    // 
    // 0: Distance offset ( m )
    // 1: Time ( minutes )
    // 2: Required Speed ( minutes/meter )
    // 3: Leg kph - Informational only.
    
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
        [  200,  13.5 ], //  200k in 13.5h 
        [  300,  20.0 ], //  300k in 20.0h
        [  400,  27.0 ], //  400k in 27.0h 		
        [  600,  40.0 ], //  600k in 40.0h 		
        [ 1000,  75.0 ], // 1000k in 75.0h		
        [ 1200,  90.0 ], // 1200k in 90.0h
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
        [    0,        0 ] 
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
    // RM60-70-80
    // -------------------------------------------------------------
    const acp_90_rm80_lut = [
        [    0,     0 ],
        [  200,  10.8 ], //  200k in 10:48h 
        [  300,  16.0 ], //  300k in 16:00h
        [  400,  27.0 ], //  400k in 21:36h 		
        [  600,  32.0 ], //  600k in 32:00h 		
        [ 1000,  60.0 ], // 1000k in 60:00h // Added by RS.  Not official.		
        [    0,     0 ] 
    ];

    const acp_90_rm70_lut = [
        [    0,      0 ],
        [  200,  9.45 ], //  200k in  9:27h 
        [  300, 14.00 ], //  300k in 14:00h
        [  400, 18.90 ], //  400k in 18:54h 		
        [  600, 28.00 ], //  600k in 28:00h 		
        [ 1000, 52.50 ], // 1000k in 52:30h // Added by RS.  Not official.		
        [    0,     0 ]
    ];

    const acp_90_rm60_lut = [
        [    0,     0 ],
        [  200,   8.1 ], //  200k in  8:06h 
        [  300,  12.0 ], //  300k in 12:00h
        [  400,  16.2 ], //  400k in 16:12h 		
        [  600,  24.0 ], //  600k in 24:00h 		
        [ 1000,  45.0 ], // 1000k in 45:00h // Added by RS.  Not official.		
        [    0,     0 ] 
    ];


    // -------------------------------------------------------------
    // Tables of tables.
    // -------------------------------------------------------------

    // These lists will be indexed by the user config settings.
    const luts as Array = [
        acp_90_lut,
        pbp_90_lut, pbp_84_lut, pbp_80_lut, 
        straight_90_lut, 
        rusa_lut, 
        lel125_lut,
        acp_90_rm80_lut, acp_90_rm70_lut, acp_90_rm60_lut 
        ];

    // Displayable table names.
    const method_names = [
        "ACP90",
        "PBP90", "PBP84", "PBP80",
        "RM90",
        "RUSA",
        "LEL128",
        "R80", "R70", "R60"
        ];

    // --------------------------------------------------------------
    // --------------------------------------------------------------
    // --------------------------------------------------------------
    // --------------------------------------------------------------
    // --------------------------------------------------------------
    // --------------------------------------------------------------
    public var BankedTime     as Float; // Final calulated value.
    public var method_name    as String;

    // --------------------------------------------------------------
    // Internal State.
    // --------------------------------------------------------------
    protected var table_entry as Number;
    protected var lut         as Array<Array>;

    public function initialize( which_flavor as String) {
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

        var base_lut      = luts[which_flavor] as Array<Array>;
        var base_lut_len  = luts[which_flavor].size();

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
    public function update( distance as Float, elapsed_mins as Float) as Void {
        // Figure out which entry.
        // Simplify this to a check for the next one.
        
        // If the next entry is less than the distance so far
        // and the next entry isn't zero, use that one.
        // Do this in a greedy way so that you can restart.

        // Check for distance first, as that usually will fail.
        var next = table_entry + 1;
        while( distance > lut[next][0] && lut[next][0] != 0 ) {
            next        += 1;
            table_entry += 1;
        } 

        var i = table_entry;

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

// -------------------------------------------------
// Sanity Checks.   Straight time is simple.
// -------------------------------------------------
(:test)
function EngineTestStr90(logger as Logger) as Boolean {
    var engine = new RandoCalcEngine(4);

    logger.debug("EngineTestStr90.  method_name =" + engine.method_name );

    Test.assertMessage(engine.method_name.equals("RM90"), "Bad Init Value");

    // This had better return with 0 minutes in hand.
    logger.debug("EngineTestStr90. Starting Time=" + engine.BankedTime );

    Test.assertMessage( engine.BankedTime == 0.0, "Banked Time should init as 0!");

    engine.update(600 * 1000.0, 45 * 60.0 );

    Test.assertMessage(engine.BankedTime == 0.0, "Not on schedule");

    logger.debug("EngineTestStr90. 1 H Early=" + engine.BankedTime );

    engine.update(1200 * 1000.0, 89 * 60.0 );
    Test.assertMessage(engine.BankedTime == 60.0, "Not on schedule");


    return( true );
}

// -------------------------------------------------
// ACP-90 has tables/Rows.  Write a test 
// that hits most of the interesting points.
// -------------------------------------------------
// Run it all, applying straight time.
(:test)
function EngineTestACP90Sweep(logger as Logger) as Boolean {
    var testname = "EngineTestACP90Sweep";
    var engine = new RandoCalcEngine(0);
    var d = 0.0;

    for( var t = 0; t <= 80; t += 1 ) {
        d = t * 15.0; 
        engine.update(d * 1000.0, t * 60.0  );
        logger.debug(testname + ". " + t + "H @" + d + "=" + engine.BankedTime );

        }
    return( true );
}


(:test)
function EngineTestACP90Seq(logger as Logger) as Boolean {
    var testname = "EngineTestACP90Seq";
    var engine = new RandoCalcEngine(0);
    var d = 0.0;
    var t = 0.0; 

    logger.debug( testname + ".  method_name =" + engine.method_name );
    Test.assertMessage(engine.method_name.equals("ACP90"), "Bad Init Value");

    // Start 
    logger.debug(testname + ". In-hand at start=" + engine.BankedTime );
    Test.assertMessage( engine.BankedTime == 0.0, "Banked Time should init as 0!");

    // 100k in 5:45 ( not 6:45 )
    d = 100.0; t = 13.5/2 - 1.0; 
    engine.update(d * 1000.0, t * 60.0  );
    logger.debug(testname + ". 1 H Early @100k =" + engine.BankedTime );
    Test.assertMessage(engine.BankedTime == 60.0, "Not on schedule");

    // 200k in 13:30 
    d = 200.0; t = 13.5; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". On-Time @200k =" + engine.BankedTime );
    Test.assertMessage(engine.BankedTime == 0.0, "Not on schedule");

    // 201k in 13:42 - On time with linear interpretation.
    d = 203.0; t = 13.7; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". On-Time @203k =" + engine.BankedTime );
    // Test.assertMessage(engine.BankedTime == 0.0, "Not on schedule");

    // 250k in 13:42 - On time with linear interpretation.
    d = 250.0; t = 16.66666666666667; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". On-Time @250k =" + engine.BankedTime );
    // Test.assertMessage(engine.BankedTime == 0.0, "Not on schedule");

    // 255k in 17h 
    d = 255.0; t = 17.0; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". On-Time @255k =" + engine.BankedTime );
    // Doesn't line up perfectly between 200k and 300k.
    // Test.assertMessage(engine.BankedTime == 60.0, "Not on schedule");

    // 285k in 19h 
    d = 285.0; t = 19.0; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". On-Time @285k =" + engine.BankedTime );
    // Doesn't line up perfectly between 200k and 300k.
    // Test.assertMessage(engine.BankedTime == 60.0, "Not on schedule");

    // 285k in 20h 
    d = 285.0; t = 20.0; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". Late 1h @285k =" + engine.BankedTime );
    // Doesn't line up perfectly between 200k and 300k.
    // Test.assertMessage(engine.BankedTime == -60.0, "Not on schedule");

    // 300k in 21h 
    d = 300.0; t = 21.0; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". Late 1h @300k =" + engine.BankedTime );
    Test.assertMessage(engine.BankedTime == -60.0, "Not on schedule");

    // 330k in 22h 
    d = 330.0; t = 22.0; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". On-Time @330k =" + engine.BankedTime );
    // Test.assertMessage(engine.BankedTime == -60.0, "Not on schedule");


    // 345k in 23h - Should be on time.
    d = 345.0; t = 23.0; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". On Time @345k =" + engine.BankedTime );
    // Test.assertMessage(engine.BankedTime == 0.0, "Not on schedule");

    // 385k in 39h - Should be on time.
    d = 385.0; t = 26.0; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". On Time @385k =" + engine.BankedTime );
    // Test.assertMessage(engine.BankedTime == 0.0, "Not on schedule");


    return( true );
}

(:test)
function EngineTestACP90Restart(logger as Logger) as Boolean {
    var testname = "EngineTestACP90Restart";
    var d = 0.0;
    var t = 0.0; 

    var engine = new RandoCalcEngine(0);
    logger.debug( testname + ".  method_name =" + engine.method_name );
    Test.assertMessage(engine.method_name.equals("ACP90"), "Bad Init Value");
    Test.assertMessage(engine.BankedTime == 0.0, "Init Error");


    engine =  new RandoCalcEngine(0);
    // 100k in 5:45 ( not 6:45 )
    d = 100.0; t = 13.5/2 - 1.0; 
    engine.update(d * 1000.0, t * 60.0  );
    logger.debug(testname + ". 1 H Early @100k =" + engine.BankedTime );
    Test.assertMessage(engine.BankedTime == 60.0, "Not on schedule");

    engine =  new RandoCalcEngine(0);
    // 200k in 13:30 
    d = 200.0; t = 13.5; 
    engine.update(d * 1000.0, t * 60.0  );
    logger.debug(testname + ". On time @200k =" + engine.BankedTime );
    Test.assertMessage(engine.BankedTime == 0.0, "Not on schedule");

    engine =  new RandoCalcEngine(0);
    // 300k in 21h 
    d = 300.0; t = 21.0; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". Late 1h @300k =" + engine.BankedTime );
    Test.assertMessage(engine.BankedTime == -60.0, "Not on schedule");

    engine = new RandoCalcEngine(0);
    // 400k in 26h 
    d = 400.0; t = 26.0; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". Early 1h @400k =" + engine.BankedTime );
    Test.assertMessage(engine.BankedTime == 60.0, "Not on schedule");

    engine = new RandoCalcEngine(0);
    // 600k in 41h 
    d = 600.0; t = 41.0; 
    engine.update(d * 1000.0, t * 60.0 );
    logger.debug(testname + ". Late 1h @600k =" + engine.BankedTime );
    Test.assertMessage(engine.BankedTime == -60.0, "Not on schedule");

    return( true );
}
