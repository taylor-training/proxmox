#!/bin/bash

if [ ! -f ./setup.conf ]; then
    echo "Unable to find setup file"
    exit 1
fi

source ./setup.conf

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

let START_ID=($TEMPLATE_ID_START + 10)
echo "Using start ID of ${START_ID}"

create_template $START_ID "Fedora-40" "Fedora-40.qcow2" true "fedora,fedora-40"