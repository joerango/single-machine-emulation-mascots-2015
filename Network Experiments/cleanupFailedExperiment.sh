#!/bin/bash
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
