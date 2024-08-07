#!/bin/bash

### VARS ###
SERVER_IP="192.168.50.53"
NET_GATEWAY="192.168.50.1"
NET_DEVICE_NAME="ens18"
NET_DOMAIN="taylor.lan"
NET_HOST="dns"
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

systemctl disable systemd-resolved
systemctl stop systemd-resolved

ls -lh /etc/resolv.conf
rm /etc/resolv.conf

cat << EOF > /etc/resolv.conf
nameserver ${SERVER_IP}
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

apt-get install -y dnsmasq dnsutils

cat << EOF > /etc/dnsmasq.conf
port=53
domain-needed
bogus-priv
strict-order
expand-hosts
domain=${NET_DOMAIN}
listen-address=${SERVER_IP}
EOF

echo "${SERVER_IP} ${NET_HOST} ${NET_HOST}.${NET_DOMAIN}" >> /etc/hosts

shutdown -r +2 "DNS Server apply"