#!/bin/sh
#
# Start with a ridewithgpx history .tcx file.
# This is relatively expensive for a big file.
#
# You need xmlstarlet 
# Args: Input file name
#
# Notes:  The files from RWGPS contain schema declarations
# in the <TrainingCenterDatabase> declaration.  Remove them.

[ -r $1 ] || { echo "Usage: $0 <Input File>"; exit 1; } 


BASE=${1%.tcx}

# Use the sort command to keep one data point per minute, max.
# Not all data sets are aligned on the second, so you can't 
# use second == 0 
xml sel --template --match TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint \
	--value-of 'Time' -o ' ' --value-of DistanceMeters  --nl $1 |\
	sort  -t':' -k1,2 --unique > $BASE-raw.txt 

#	grep 00Z > $BASE-raw.txt 
