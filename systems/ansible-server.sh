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

apt-get install -y dnsutils resolvconf

systemctl start resolvconf
systemctl enable resolvconf

cat << EOF > /etc/resolvconf/resolv.conf.d/head
nameserver ${DNS_IP}
nameserver ${PUBLIC_NS1}
nameserver ${PUBLIC_NS2}
EOF

shutdown -r +2 "Server info apply"

apt-get install -y python3 python3-pip
python3 -m pip install --user ansible
