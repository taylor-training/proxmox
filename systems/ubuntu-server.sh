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

apt-get update -y
apt-get upgrade -y

apt-get install -y dnsutils resolvconf

systemctl start resolvconf
systemctl enable resolvconf

cat << EOF > /etc/resolvconf/resolv.conf.d/head
nameserver ${DNS_IP}
nameserver ${PUBLIC_NS1}
nameserver ${PUBLIC_NS2}
EOF

shutdown -r +2 "Server info apply"