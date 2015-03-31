#!/bin/bash
./experiment1.sh
python LogParser.py ping.log queue.log
gnuplot -c plotAll.plt queue1.dat queue2.dat ping.dat experiment1.png
mkdir experiment1
mv *.log experiment1/
mv *.dat experiment1/
mv *.png experiment1/

./experiment2.sh
python LogParser.py ping.log queue.log
gnuplot -c plotAll.plt queue1.dat queue2.dat ping.dat experiment2.png
mkdir experiment2
mv *.log experiment2/
mv *.dat experiment2/
mv *.png experiment2/

./experiment3.sh
python LogParser.py ping.log queue.log
gnuplot -c plotAll.plt queue1.dat queue2.dat ping.dat experiment3.png
mkdir experiment3
mv *.log experiment3/
mv *.dat experiment3/
mv *.png experiment3/

./experiment4.sh
python LogParser.py ping.log queue.log
gnuplot -c plotAll.plt queue1.dat queue2.dat ping.dat experiment4.png
mkdir experiment4
mv *.log experiment4/
mv *.dat experiment4/
mv *.png experiment4/

./experiment5.sh
python LogParserwAdjusted.py ping.log queue.log
gnuplot -c plotAllwAdjusted.plt queue1.dat queue2.dat adjustedQueue.dat ping.dat experiment5.png
mkdir experiment5
mv *.log experiment5/
mv *.dat experiment5/
mv *.png experiment5/

