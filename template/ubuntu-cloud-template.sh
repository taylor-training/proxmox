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

echo "Downloading Ubuntu 24.04 LTS (Noble)"
download_image "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img" "Ubuntu-LTS-Server.img"

# create_template 100 "Ubuntu-LTS" "Ubuntu-LTS-Server.img" false
create_template $TEMPLATE_ID_START "Ubuntu-LTS" "Ubuntu-LTS-Server.img" true "ubuntu-lts,ubuntu,24.04"