file1=ARG1
file2=ARG2
file3=ARG3
outputFile=ARG4
reset

set style line 2 dashtype "."
set style line 2 lc rgb "red"

set style line 3 dashtype "-"
set style line 3 lc rgb "blue"

set autoscale
set xlabel 'Experiment Time (seconds)'
set ylabel 'bytes'
set y2label 'milliseconds'
set ytics nomirror
set y2tics
set yrange  [0 : 250000]
set style fill solid 0.5
set terminal pngcairo size 1000,500 enhanced font 'Verdana,18'
set output outputFile
plot \
file1 using 1:2 with lines title 'Queue 1 (netem)' ls 3 lw 1.5, \
file2 using 1:2 with lines title 'Queue 2 (tbf)' lw 1.5, \
file3 using 1:2 with lines title 'Round-trip time' axes x1y2 ls 2 lw 2.5

unset output
set terminal qt
