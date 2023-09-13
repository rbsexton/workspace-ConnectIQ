#!/bin/bash
#
# Usage: $0 <Rules Table> <As Ridden>
#
#cut -d' ' -f2,3,6 ../../console_log.txt | uniq | sed s/[deb]//g > processed.txt

DATA=$1
DATA2=$2 # Future use.

[ $# -eq 1 ] || { echo "Usage: $0 <file>"; exit 1; }
[ -r $DATA ] || { echo "Usage: $0 <file>"; exit 1; }

OTYPE=pdf

#############################################################
# Kilometers.   Plotting by time is sorta useless - 
# You can't ID the controls.   Its also implicit in the
# time in hand graph.
#############################################################
{
    echo set term $OTYPE
    echo set output \'plot-distance.$OTYPE\' 
    echo set xlabel '"Distance (km)"'
    echo set ylabel '"Hours in Hand"'
#    echo set title '"PBP 2023, 84h Rules"' 
    echo set title '"PBP 2023, 90h Rules"' 

    echo set xrange '[0:1250]' 
#    echo set yrange '[-2:]' 
    echo set mytics 

    for control in  119 203 292 353 378 435 482 514 604 697 731 782 842 867 928 1017 1099 1176 1219
    do   
      echo set arrow from $control, graph 0.08 to $control, graph 0 
    done

    echo 'set label "Mort"    at  119, graph 0.1 rotate by 90'
    echo 'set label "Vill"    at  213, graph 0.1 rotate by 90'
    echo 'set label "Foug"    at  292, graph 0.1 rotate by 90'
    echo 'set label "Tint"    at  353, graph 0.1 rotate by 90'
    echo 'set label "(Qued)"  at  378, graph 0.1 rotate by 90'
    echo 'set label "Loud"    at  435, graph 0.1 rotate by 90'
    echo 'set label "(StNic)" at  482, graph 0.1 rotate by 90'
    echo 'set label "Carh"    at  514, graph 0.1 rotate by 90'
    echo 'set label "Brest"   at  604, graph 0.1 rotate by 90'
    echo 'set label "Carh"    at  697, graph 0.1 rotate by 90'
    echo 'set label "(Gou)"   at  731, graph 0.1 rotate by 90'
    echo 'set label "Loud"    at  782, graph 0.1 rotate by 90'
    echo 'set label "(Qued)"  at  842, graph 0.1 rotate by 90'
    echo 'set label "Tint"    at  867, graph 0.1 rotate by 90'
    echo 'set label "Foug"    at  928, graph 0.1 rotate by 90'
    echo 'set label "Vill"    at 1017, graph 0.1 rotate by 90'
    echo 'set label "Mort"    at 1099, graph 0.1 rotate by 90'
    echo 'set label "Dreux"   at 1176, graph 0.1 rotate by 90'

    echo set xtics nomirror
    echo set mxtics 
    echo set grid x2tics
    echo set grid ytics

     echo plot \"$DATA\" using 2:\(\$3-\$1\) with lines title \"Time in Hand\"
     # echo plot \"$DATA\" using 2:\(\$3-\$1\) with lines title \"BKF\", \"$DATA2\" using 2:\(\$3-\$1\) with lines title \"JW\"
} | gnuplot


exit


