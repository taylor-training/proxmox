#!/bin/bash

ME=`whoami`

if [ "${ME}" -ne "root" ]; then
    echo "You are not root, please sudo or become root"
    exit 1
fi

read -p "Network Device (ens18): " device
read -p "Network Gateway: " gateway_ip
read -p "Network Domain: " domain
read -p "Local DNS Server: " local_dns
read -p "External DNS Server 1: " dns_1
read -p "External DNS Server 2: " dns_2


cat << EOF > ./setup.conf
NET_DEVICE_NAME=${device}
NET_GATEWAY=${gateway_ip}
NET_DOMAIN=${domain}
DNS_IP=${local_dns}
PUBLIC_NS1=${dns_1}
PUBLIC_NS2=${dns_2}
EOF