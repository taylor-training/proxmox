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

echo "Downloading Debian 12 (Bookworm)"
download_image "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2" "Debian-12.qcow2"

create_template 103 "Debian-12" "Debian-12.qcow2" false
# create_template 9120 "Debian-12" "Debian-12.qcow2" true