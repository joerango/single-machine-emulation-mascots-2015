#!/bin/bash
#Setup emulated topology
ip netns add serverns
ip netns add clientns

ip link add veth0 type veth peer name veth1
ip link add veth2 type veth peer name veth3
ip link add veth4 type veth peer name veth5

ovs-vsctl  add-br switch1
ovs-vsctl  add-br switch2

ip link set veth0 netns serverns
ip link set veth5 netns clientns

ovs-vsctl add-port switch1 veth1
ovs-vsctl add-port switch1 veth2
ovs-vsctl add-port switch2 veth3
ovs-vsctl add-port switch2 veth4

ifconfig veth1 up
ifconfig veth2 up
ifconfig veth3 up
ifconfig veth4 up

ip netns exec serverns ifconfig veth0 192.168.150.1
ip netns exec clientns ifconfig veth5 192.168.150.2

#set link conditions for bottleneck link
tc -s qdisc replace dev veth2 root handle 1:0 netem delay 50ms
tc -s qdisc add dev veth2 parent 1:1 handle 10: tbf rate 10000kbit limit 150000 burst 12000

tc -s qdisc replace dev veth3 root handle 1:0 netem delay 50ms
tc -s qdisc add dev veth3 parent 1:1 handle 10: tbf rate 10000kbit limit 150000 burst 12000


#create temp file for download
dd if=/dev/zero of=150MB.dat bs=1M count=150 

#start ping
ip netns exec clientns ping -D -i 0.2 192.168.150.1 > ping.log 2>&1 &
PING_PID=$!

#start web server
ip netns exec serverns python -m SimpleHTTPServer 80 > webserver.log 2>&1 &
WEBSERVER_PID=$!
sleep 2

#start queue monitor
rm queue.log
watch -n 0.05 'date +%s.%N >> queue.log; tc -s qdisc show dev veth2 | grep backlog >> queue.log' > /dev/null 2>&1 &
MONITOR_PID=$!

#start web download
ip netns exec clientns wget -O /dev/null http://192.168.150.1/150MB.dat &
WGET_PID=$!

sleep 120

#stop webserver, monitor, wget and ping
kill $WGET_PID
kill $WEBSERVER_PID
kill $PING_PID
kill $MONITOR_PID

#Tear down emulated topology
ip link del veth1
ip link del veth2
ip link del veth4

ovs-vsctl del-br switch1
ovs-vsctl del-br switch2

ip netns delete serverns
ip netns delete clientns

#remove temp file
rm 150MB.dat
