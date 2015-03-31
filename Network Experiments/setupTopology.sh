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
tc -s qdisc replace dev veth2 root handle 1:0 netem rate 50000kbit limit 600
tc -s qdisc add dev veth2 parent 1:0 handle 2: netem delay 50ms

tc -s qdisc replace dev veth3 root handle 1:0 netem rate 50000kbit limit 600
tc -s qdisc add dev veth3 parent 1:0 handle 2: netem delay 50ms

#enforce MTU sized packets only.
#ip netns exec serverns ethtool --offload veth0 gso off
