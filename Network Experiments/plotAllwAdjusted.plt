file1=ARG1
file2=ARG2
file3=ARG3
file4=ARG4
outputFile=ARG5
reset

set style line 2 dashtype "."
set style line 2 lc rgb "red"

set style line 3 dashtype "-"
set style line 3 lc rgb "blue"

set style line 4 dashtype "_"
set style line 4 lc rgb "dark-blue"

set autoscale
set xlabel 'Experiment Time (seconds)'
set ylabel 'bytes'
set y2label 'milliseconds'
set ytics nomirror
set y2tics
set yrange  [0 : 360000]
set y2range  [0 : 350]
set style fill solid 0.5
#set title 'Queue Utilization'
set terminal pngcairo size 1000,500 enhanced font 'Verdana,18'
set output outputFile
plot \
file1 using 1:2 with lines title 'Queue 1 (netem 1)' lw 1.5, \
file2 using 1:2 with lines title 'Queue 2 (netem 2)' ls 3 lw 1.5, \
file3 using 1:2 with lines title 'Adjusted Queue' ls 4 lw 1.5, \
file4 using 1:2 with lines title 'Round-trip time' axes x1y2 ls 2 lw 2.5

unset output
set terminal qt
