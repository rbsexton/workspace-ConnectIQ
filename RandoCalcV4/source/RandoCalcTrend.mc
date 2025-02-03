import Toybox.Lang;

import Toybox.Test;

class RandoCalcTrend
{

    public var trend_text  as String;

    protected var trend_data_banked as Array<Float> = new[31];
    protected var trend_i           as Number;

    public function initialize( ) {
        for( var i = 0; i < trend_data_banked.size(); i++ ) {
            trend_data_banked[i]  = 0.0; 
        }

        trend_i = 0;
        trend_text = "";
    }
        
    public function update( BankedTime ) {
        var trend_banked  = BankedTime   - trend_data_banked[trend_i];

        // This is sort of a violation of UI - 
        // there's representation in here.
        // The alternative is to use a boolean, and then 
        // figure out what that boolean means every single time 
        // that you update.
        if ( trend_banked > 0 ) { self.trend_text = "+";  } 
        else                    { self.trend_text = ""; } 

        trend_data_banked[trend_i]  = BankedTime;

        if ( trend_i < 30 ) { trend_i++; }
        else                { trend_i = 0; }
    }





}

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

