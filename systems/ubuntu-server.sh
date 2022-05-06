#!/bin/bash

### VARS ###
DNS_SERVER="192.168.50.53"
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
nameserver ${DNS_SERVER}
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

shutdown -r +2 "DNS Server apply"