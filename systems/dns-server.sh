#!/bin/bash

### VARS ###
SERVER_IP="192.168.50.53"
NET_GATEWAY="192.168.50.1"
NET_DEVICE_NAME="ens18"
NET_DOMAIN="radiant.lan"
NET_HOST="dns"
### END VARS ###

ME=`whoami`

if [ "$ME" != "root" ]; then 
    echo "You are not root, please sudo or become root"
    exit 1
fi

hostnamectl set-hostname "${NET_HOST}"

cat << EOF > /etc/netplan/80-networking-config.yaml
network:
    ethernets:
        ${NET_DEVICE_NAME}:
            dhcp4: false
            addresses: [${SERVER_IP}/24]
            gateway4: ${NET_GATEWAY}
            nameservers:
              addresses: [${SERVER_IP},8.8.8.8,8.8.4.4]
    version: 2
EOF

apt-get update -y
apt-get upgrade -y

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