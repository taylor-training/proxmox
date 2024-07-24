#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

ME=`whoami`

if [ "$ME" != "root" ]; then 
    echo "You are not root, please sudo or become root"
    exit 1
fi

if [ ! -f ./setup.conf ]; then
    echo "Cannot find setup file, run setup script first"
    exit 1
fi

source ./setup.conf

echo "Resolver setup"

apt-get install -y dnsutils systemd-resolved

systemctl start resolvconf
systemctl enable resolvconf

cat << EOF > /etc/resolvconf/resolv.conf.d/head
nameserver ${DNS_IP}
nameserver ${PUBLIC_NS1}
nameserver ${PUBLIC_NS2}
EOF

echo "Resolver update completed"

shutdown -r +2 "Server info apply"

echo "install Python and Ansible"
apt-get install -y python3 python3-pip ansible git nano

