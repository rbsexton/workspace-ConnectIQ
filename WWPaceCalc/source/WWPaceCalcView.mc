using Toybox.WatchUi;

class WWPaceCalcView extends WatchUi.SimpleDataField {

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "WWPace";
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
  		// Western Wheelers Pace: Average Speed + Hilliness
  		// Where Hilliness is feet/mile/25
  		// All of this has been converted to Metric.
    
    	// Hilliness = 0.211286 m / km
        if ( info.totalAscent == null ||
             info.elapsedDistance == null ||
             info.averageSpeed == null ) {

        	return(0);			        
			}             
        
        // The math can produce crazy results when you don't 
        // have enough data, so don't calculate that.

        var hilliness;                   
        if ( info.elapsedDistance > 1000 ) {  
        	hilliness = (211.2 * info.totalAscent) / ( info.elapsedDistance );
            }
        else { hilliness = 0; }
               
        var avg_mph;
        avg_mph = 2.23694 * info.averageSpeed;

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
                                
   	    return( hilliness + avg_mph );        
    }

}