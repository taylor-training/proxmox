#!/bin/bash

source ./proxmox-lib.sh

ME=`whoami`

if [ "${ME}" -ne "root" ]; then
    echo "You are not root, please sudo or become root"
    exit 1
fi

echo "Making the keys file"
make_auth_keys

echo "Downloading Fedora 40"
download_image "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2" "Fedora-40.qcow2"

create_template 101 "Fedora-40" "Fedora-40.qcow2" false
# create_template 9110 "Fedora-40" "Fedora-40.qcow2" true