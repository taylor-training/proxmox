#!/bin/bash

### VARS ###
DNS_IP="192.168.50.53"
NET_GATEWAY="192.168.50.1"
NET_DEVICE_NAME="ens18"
### END VARS ###

SERVER_NAME=$1
SERVER_IP=$2

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
              addresses: [${DNS_IP},8.8.8.8,8.8.4.4]
    version: 2
EOF

apt-get update -y
apt-get upgrade -y

apt-get install -y dnsutils resolvconf

systemctl start resolvconf
systemctl enable resolvconf

cat << EOF > /etc/resolvconf/resolv.conf.d/head
nameserver ${DNS_IP}
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

shutdown -r +2 "Server info apply"