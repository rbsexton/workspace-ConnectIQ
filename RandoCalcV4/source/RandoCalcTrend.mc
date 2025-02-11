import Toybox.Lang;

import Toybox.Test;

class RandoCalcTrend
{

    public var trend_text  as String = "";

    // This is a ring buffer.   
    // trend_i always points to the oldest data item.
    // Note: This code doesn't really need to support 
    // re-configuration.  Any oddness that happens will 
    // clear up in 30s or so. 

    // The math looks a little odd here.  The intent is that
    // you have 31 entries, so the last sample is 30s old.

    const TREND_LEN = 31;

    protected var trend_data_banked as Array<Float> = new[TREND_LEN];
    protected var trend_i as Number = 0; // Docs say 32-bit.
    
    public function initialize( ) {
        for( var i = 0; i < TREND_LEN; i++ ) {
            trend_data_banked[i]  = 0.0; 
        }
    }
        
    public function update( BankedTime as Float ) as Void {
        var trend_banked  = BankedTime   - trend_data_banked[trend_i];

        // This is sort of a violation of UI - 
        // there's representation in here.
        // The alternative is to use a boolean, and then 
        // figure out what that boolean means every single time 
        // that you update.
        if ( trend_banked > 0 ) { self.trend_text = "+";  } 
        else                    { self.trend_text = ""; } 

        trend_data_banked[trend_i] = BankedTime;

        if ( trend_i < (    TREND_LEN-1) ) { trend_i++; }
        else                { trend_i = 0; }
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
function UnitTestNotMoving(logger as Logger) as Boolean {
    var trend = new RandoCalcTrend();

    for( var i = 0; i < 40; i++ ) {
       trend.update(60.0);
    }

    logger.debug("UnitTestNotMoving.  trend_text =" + trend.trend_text );

    return(trend.trend_text.equals("") );
}

(:test)
function UnitTestMoving(logger as Logger) as Boolean {
    var trend = new RandoCalcTrend();

    for( var i = 0; i < 40 ; i++ ) {
       trend.update(60.0+ 1.0 * i);
    }

    logger.debug("UnitTestMoving.  trend_text =" + trend.trend_text );
    return( trend.trend_text.equals("+") );
}

