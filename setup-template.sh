#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="${SCRIPT_DIR}/template/setup.conf"
DEFAULT_CLOUD_INIT_CONFIG_ROOT="${SCRIPT_DIR}/configs"

if [ "$(id -u)" -ne 0 ]; then
    echo "You are not root, please sudo or become root"
    exit 1
fi

read -r -p "User: " username
read -r -p "Pass: " user_pass

read -r -p "Cores: " cores
read -r -p "Memory (in GB): " memory
let memory_gb=memory*1024
echo "Memory (in MB): ${memory_gb} MB"

read -r -p "Storage Device: " storage
read -r -p "Default VM disk space (in GB): " disk_space
read -r -p "Template base disk size [10G]: " template_base_disk
template_base_disk="${template_base_disk:-10G}"

read -r -p "SSH Keys Filename: " sshkeys_file

read -r -p "Network Address (First Three Sets): " network

read -r -p "Search Domain: " domain
read -r -p "NameServers (separate entries with a space): " nameservers

read -r -p "Template Starting ID: " template_start_id

read -r -p "Cloud-init config root [${DEFAULT_CLOUD_INIT_CONFIG_ROOT}]: " cloud_init_config_root
cloud_init_config_root="${cloud_init_config_root:-${DEFAULT_CLOUD_INIT_CONFIG_ROOT}}"

read -r -p "Cloud-init snippet storage [local]: " cloud_init_snippet_storage
cloud_init_snippet_storage="${cloud_init_snippet_storage:-local}"

read -r -p "Cloud-init snippet directory [/var/lib/vz/snippets]: " cloud_init_snippet_dir
cloud_init_snippet_dir="${cloud_init_snippet_dir:-/var/lib/vz/snippets}"

cat << EOF > "${OUTPUT_FILE}"
VM_USER=${username}
VM_PASS=${user_pass}
VM_CORES=${cores}
VM_MEMORY=${memory_gb}
VM_DEVICE=${storage}
VM_SPACE=${disk_space}G
TEMPLATE_BASE_DISK=${template_base_disk}
SSHKEYS_FILE=${sshkeys_file}
VM_NETWORK=${network}
SEARCH_DOMAIN=${domain}
NAME_SERVERS=${nameservers}
TEMPLATE_ID_START=${template_start_id}
CLOUD_INIT_CONFIG_ROOT=${cloud_init_config_root}
CLOUD_INIT_SNIPPET_STORAGE=${cloud_init_snippet_storage}
CLOUD_INIT_SNIPPET_DIR=${cloud_init_snippet_dir}
VERIFY_IMAGE_CHECKSUM=true
VERIFY_IMAGE_GPG=false
VALIDATE_SETUP_CONF=true
EOF

echo "Saved setup to ${OUTPUT_FILE}"
