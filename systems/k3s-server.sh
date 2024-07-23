#!/bin/bash

### VARS ###
SERVER_IP="192.168.50.41"
NET_HOST="k3s-server"
K3S_TOKEN="mysecret"
### END VARS ###

export DEBIAN_FRONTEND=noninteractive

ME=`whoami`

if [ "$ME" != "root" ]; then 
    echo "You are not root, please sudo or become root"
    exit 1
fi

wget --no-cache -qO server-config.sh https://raw.githubusercontent.com/taylor-training/proxmox/main/systems/server-config.sh
source server-config.sh

wget --no-cache -qO ubuntu-server.sh https://raw.githubusercontent.com/taylor-training/proxmox/main/systems/ubuntu-server.sh
source ubuntu-server.sh

curl -sfL https://get.k3s.io | sudo K3S_TOKEN=${K3S_TOKEN} sh -

shutdown -r +2 "K3S Server apply"