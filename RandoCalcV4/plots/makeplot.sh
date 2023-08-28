#!/bin/bash
#
# Usage: $0 <Rules Table> <As Ridden>
#
#cut -d' ' -f2,3,6 ../../console_log.txt | uniq | sed s/[deb]//g > processed.txt

RULES=$1
DATA=$2

[ -r $RULES ] || exit 1;

LC=0 #Linecount for reading.

# Declare the arrays.
declare -a KM
declare -a HR
declare -a KPH


#############################################################
# GnuPlot Output
#############################################################

{
    echo set term pdf
    echo set output \'plot1.pdf\' 
    echo set ylabel '"Distance (km)"'
    echo set xlabel '"Hours"'
    echo set x2tics '("0h" 5.75, "0h" 29.75, "0h" 53.75, "0h" 77.5 )'
    echo set xtics nomirror
    echo set grid x2tics
    echo plot '"timetable-pbp90-2023.txt" using 2:1 with linespoints title "PBP Close Times" , "rs.txt" using 1:($2/1000.0) with lines title "RS Ride"'
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


