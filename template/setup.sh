#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "You are not root, please sudo or become root"
    exit 1
fi

read -p "User: " username
read -p "Pass: " user_pass

read -p "Cores: " cores
read -p "Memory (in GB): " memory
let memory_gb=memory*1024
echo "Memory (in MB): ${memory_gb} MB"

read -p "Storage Device: " storage
read -p "Default VM disk space (in GB): " disk_space

read -p "SSH Keys Filename: " sshkeys_file

read -p "Network Address (First Three Sets): " network

read -p "Search Domain: " domain
read -p "NameServers (separate entries with a space): " nameservers

read -p "Template Starting ID: " template_start_id


cat << EOF > "${SCRIPT_DIR}/setup.conf"
VM_USER=${username}
VM_PASS=${user_pass}
VM_CORES=${cores}
VM_MEMORY=${memory_gb}
VM_DEVICE=${storage}
VM_SPACE=${disk_space}G
SSHKEYS_FILE=${sshkeys_file}
VM_NETWORK=${network}
SEARCH_DOMAIN=${domain}
NAME_SERVERS=${nameservers}
TEMPLATE_ID_START=${template_start_id}
VERIFY_IMAGE_CHECKSUM=true
VERIFY_IMAGE_GPG=false
VALIDATE_SETUP_CONF=true
EOF

echo "Saved setup to ${SCRIPT_DIR}/setup.conf"