#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/systems/setup.conf"

if [ "$(id -u)" -ne 0 ]; then
    echo "You are not root, please sudo or become root"
    exit 1
fi

read -r -p "Network Device (ens18): " device
read -r -p "Network Gateway: " gateway_ip
read -r -p "Network Domain: " domain
read -r -p "Local DNS Server: " local_dns
read -r -p "External DNS Server 1: " dns_1
read -r -p "External DNS Server 2: " dns_2

cat << EOF > "${OUTPUT_FILE}"
NET_DEVICE_NAME=${device}
NET_GATEWAY=${gateway_ip}
NET_DOMAIN=${domain}
DNS_IP=${local_dns}
PUBLIC_NS1=${dns_1}
PUBLIC_NS2=${dns_2}
EOF

echo "Saved setup to ${OUTPUT_FILE}"
