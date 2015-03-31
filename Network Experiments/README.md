###Instructions to replicate the network emulation results shown in the paper.
Each experiment{n}.sh file sets up the experiment topology, applies the specific the specific link characteristics as discussed in the paper, and plot the results. 

####Prerequisites
The script was tested with the following software:
* Ubuntu 14.04.1
* Linux Kernel 3.13+
* Open vSwitch (kernel module)
* Gnuplot 5.0 patchlevel 0
* Python 2.7.6


####To reproduce all experiment results, execute the following script as root:
```
reproduceResults.sh
```
Produced log files and plots will be saved in folders numbered experiment{1-5}.
