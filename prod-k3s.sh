#!/bin/bash

./systems/ubuntu-server.sh k3s-prod-server1 17 "k3s,prod,server,kubernetes"
./systems/ubuntu-server.sh k3s-prod-server2 18 "k3s,prod,server,kubernetes"
./systems/ubuntu-server.sh k3s-prod-server3 19 "k3s,prod,server,kubernetes"
./systems/ubuntu-server.sh k3s-prod-node1 23 "k3s,prod,node,kubernetes"
./systems/ubuntu-server.sh k3s-prod-node2 24 "k3s,prod,node,kubernetes"
./systems/ubuntu-server.sh k3s-prod-node3 25 "k3s,prod,node,kubernetes"
./systems/ubuntu-server.sh k3s-prod-node4 26 "k3s,prod,node,kubernetes"
./systems/ubuntu-server.sh k3s-prod-node5 27 "k3s,prod,node,kubernetes"