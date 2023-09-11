#!/bin/bash
#
# Usage: $0 <Rules Table> <As Ridden>
#
#cut -d' ' -f2,3,6 ../../console_log.txt | uniq | sed s/[deb]//g > processed.txt

DATA=$1

[ -r $DATA ] || exit 1;


#############################################################
# GnuPlot Output
#############################################################

{
    echo set term png
    echo set output \'plot2.png\' 
    echo set xlabel '"Distance (km)"'
    echo set ylabel '"Hours in Hand"'
    echo set title '"90-Hour Limit"' 

    #echo set x2data time
    # echo set timefmt '"%H:%M:%S"'
    # echo 'set x2range["18:00:00":"110:00:00"]'
    # echo 'set x2tics format "%H"'
    # echo 'set x2tics  "18:00:00", "00:30:00"'

    echo set xrange '[0:1250]' 
    echo set yrange '[-6:6]' 
    echo set mytics
    echo set x2range '[0:92]' 
    echo set x2tics 0, 6
#    echo set x2tics '("V" 200.0, "Loud" 400,  "Brest" 613.0, "Dreux" 1200.0 )'
#    echo 'set format "%h"'
     for control in  119 203 292 353 378 435 482 514 604 697 731 782 842 867 928 1017 1099 1176 1219
	do
     	echo set arrow from $control, graph 0.08 to $control, graph 0 
     done
     echo 'set label "Mort" at 119, graph 0.1 rotate by 90'
     echo 'set label "Vill" at 213, graph 0.1 rotate by 90'
     echo 'set label "Foug" at 292, graph 0.1 rotate by 90'
     echo 'set label "Tint" at 353, graph 0.1 rotate by 90'
     echo 'set label "(Qued)" at 378, graph 0.1 rotate by 90'
     echo 'set label "Loud" at 435, graph 0.1 rotate by 90'
     echo 'set label "(StNic)" at 482, graph 0.1 rotate by 90'
     echo 'set label "Carh" at 514, graph 0.1 rotate by 90'
     echo 'set label "Brest" at 604, graph 0.1 rotate by 90'
     echo 'set label "Carh" at 697, graph 0.1 rotate by 90'
     echo 'set label "(Gou)" at 731, graph 0.1 rotate by 90'
     echo 'set label "Loud" at 782, graph 0.1 rotate by 90'
     echo 'set label "(Qued)" at 842, graph 0.1 rotate by 90'
     echo 'set label "Tint" at 867, graph 0.1 rotate by 90'
     echo 'set label "Foug" at 928, graph 0.1 rotate by 90'
     echo 'set label "Vill" at 1017, graph 0.1 rotate by 90'
     echo 'set label "Mort" at 1099, graph 0.1 rotate by 90'
     echo 'set label "Dreux" at 1176, graph 0.1 rotate by 90'
#     set label "arrow" at 1,1
#    echo set arrow from 435, graph 0 to 435, graph 1 nohead
#    echo set arrow from 604, graph 0 to 604, graph 1 nohead
#    echo set label '"Villaines" right at 100, 0.45 offset -.5, 0'
#    echo set arrow 1 from first 100, 0.45 to 213, 0.0 lt 1 lw 2 front size .3, 15
    echo set xtics nomirror
    echo set mxtics 
    echo set grid x2tics
    echo set grid ytics
    echo plot '"PBP_2023-bkf-processed.txt" using 2:($3-$1) with lines title "BKF Ride", "PBP_2023-rs-processed.txt" using 2:($3-$1) with lines title "RS Ride"'
}  | gnuplot

# echo plot "pbp90.txt" using  $2 $1 with linespoints title "PBP Maximum"

exit



f(x) = 15*x
set ytics nomirror
set y2tics
set y2grid
set ylabel  "distance (km)"
set y2label "hours in hand"
set xlabel  "hours ridden"
plot "processed.txt" using ($2/60):($1/1000) with lines title "Logged", f(x) title "ACP 15kph",
 ot  "processed.txt" using ($2/60):($3/60) axis x1y2 with lines title "Time in Hand"


Distance (x) Hours (y)
set y2range [-2:4]
set ytics nomirror
set grid y2tics
set grid xtics
set y2tics
set xlabel "distance (km)"
f(x) = x/15
set ylabel "hours ridden"
set y2label "time in hand (h)"
plot "processed.txt" using ($1/1000):($2/60) with lines title "GPS Data", f(x) title "ACP Maximum (15kph)", "processed.txt" using ($1/1000):($3/60) axis x1y2 with lines title "Time in Hand" , "pbp90.txt" using ($1/1000):($2/60) with linespoints title "PBP Maximum"


