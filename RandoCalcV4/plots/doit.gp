cut -d' ' -f2,3,6 ../../console_log.txt | uniq | sed s/[deb]//g > processed.txt


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


