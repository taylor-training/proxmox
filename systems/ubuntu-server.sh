#!/bin/bash

### VARS ###
DNS_IP="192.168.50.53"
NET_GATEWAY="192.168.50.1"
NET_DEVICE_NAME="ens18"
### END VARS ###

ME=`whoami`

if [ "$ME" != "root" ]; then 
    echo "You are not root, please sudo or become root"
    exit 1
fi

hostnamectl set-hostname ubuntu-server

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