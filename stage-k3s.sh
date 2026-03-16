#!/bin/bash

# Run on Homelab 3

qm shutdown 104
qm shutdown 105
qm shutdown 106
qm shutdown 107

sleep 20  # Wait for VMs to fully shut down

qm destroy 104 --destroy-unreferenced-disks
qm destroy 105 --destroy-unreferenced-disks
qm destroy 106 --destroy-unreferenced-disks
qm destroy 107 --destroy-unreferenced-disks

sleep 20  # Wait for VMs to fully shut down

./systems/ubuntu-server.sh k3s-stage-server 14 "k3s,stage,server,kubernetes" --cpu 8 --memory 4 --disk 200
./systems/ubuntu-server.sh k3s-stage-node1 20 "k3s,stage,node,kubernetes" --cpu 6 --memory 4 --disk 200
./systems/ubuntu-server.sh k3s-stage-node2 21 "k3s,stage,node,kubernetes" --cpu 6 --memory 4 --disk 200
./systems/ubuntu-server.sh k3s-stage-node3 22 "k3s,stage,node,kubernetes" --cpu 6 --memory 4 --disk 200