#!/bin/sh
#
# Start with a ridewithgpx history .tcx file.
#
# You need xmlstarlet 

FRAC=(.0000 .0167 .0333 .0500 .0667 .0833 .1000 .1167 .1333 .1500 .1667 .1833 .2000 .2167 .2333 .2500 .2667 .2833 .3000 .3167 .3333 .3500 .3667 .3833 .4000 .4167 .4333 .4500 .4667 .4833 .5000 .5167 .5333 .5500 .5667 .5833 .6000 .6167 .6333 .6500 .6667 .6833 .7000 .7167 .7333 .7500 .7667 .7833 .8000 .8167 .8333 .8500 .8667 .8833 .9000 .9167 .9333 .9500 .9667 .9833) 

#xml sel --template --match TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint \
#	--value-of 'Time' -o ',' --value-of DistanceMeters  --nl PBP_2023.tcx |\
#	grep 00Z > filtered.txt 

set -- $( head -1 filtered.txt ) 
BASETIME=$( date -jf "%FT%TZ" $1 +%s ) 

echo "Basetime $BASETIME"

cat filtered.txt  | while read line 
do
	set -- $line 
	T=$(( $( date -jf "%FT%TZ" $1 +%s ) - $BASETIME ))
	H=$(( $T / 3600 ))
	M=$(( ( $T / 60 ) % 60  ))
	#F=$(( ($T - $BASETIME) % 00 ))
	printf "%s %s %s\n" $H${FRAC[$M]} $2 

done
