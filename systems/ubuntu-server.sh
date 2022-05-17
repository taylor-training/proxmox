#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

SERVER_NAME=$1
SERVER_IP=$2

if [ -f server-config.sh ]; then
    rm server-config.sh
fi

wget --no-cache -qO server-config.sh https://raw.githubusercontent.com/taylor-training/proxmox/main/systems/server-config.sh
source server-config.sh

ME=`whoami`

if [ "$ME" != "root" ]; then 
    echo "You are not root, please sudo or become root"
    exit 1
fi

hostnamectl set-hostname ${SERVER_NAME}

cat << EOF > /etc/netplan/80-networking-config.yaml
network:
    ethernets:
        ${NET_DEVICE_NAME}:
            dhcp4: false
            addresses: [${SERVER_IP}/24]
            gateway4: ${NET_GATEWAY}
            nameservers:
              addresses: [${DNS_IP},${PUBLIC_NS1},${PUBLIC_NS2}]
    version: 2
EOF

apt-get update -y
apt-get upgrade -y

apt-get install -y dnsutils resolvconf qemu-guest-agent

systemctl start resolvconf
systemctl enable resolvconf

cat << EOF > /etc/resolvconf/resolv.conf.d/head
nameserver ${DNS_IP}
nameserver ${PUBLIC_NS1}
nameserver ${PUBLIC_NS2}
EOF

shutdown -r +2 "Server info apply"