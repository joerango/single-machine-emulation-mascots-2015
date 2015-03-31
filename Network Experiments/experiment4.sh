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
tc -s qdisc replace dev veth2 root handle 5: htb default 1
tc -s class add dev veth2 parent 5:0 classid 5:1 htb rate 10Mbit
tc -s qdisc add dev veth2 parent 5:1 handle 10: netem delay 50ms limit 100

tc -s qdisc replace dev veth3 root handle 5: htb default 1
tc -s class add dev veth3 parent 5:0 classid 5:1 htb rate 10Mbit
tc -s qdisc add dev veth3 parent 5:1 handle 10: netem delay 50ms limit 100

#enforce MTU sized packets only.
ip netns exec serverns ethtool --offload veth0 gso off
ip netns exec serverns ethtool --offload veth0 tso off
ip netns exec serverns ethtool --offload veth0 gro off

ip netns exec clientns ethtool --offload veth5 gso off
ip netns exec clientns ethtool --offload veth5 tso off
ip netns exec clientns ethtool --offload veth5 gro off

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
