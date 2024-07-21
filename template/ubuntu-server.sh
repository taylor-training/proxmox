#!/bin/bash

if [ ! -f ./setup.conf ]; then
    echo "Unable to find setup file"
    exit 1
fi

source ./setup.conf
source ./proxmox-lib.sh

ME=`whoami`

if [ "$ME" ne "root" ]; then 
    echo "You are not root, please sudo or become root"
    exit 1
fi

VM_ID=$1
VM_NAME=$2
VM_IP=$3
TAGS=$4

clone_template $TEMPLATE_ID_START $VM_ID $VM_NAME $VM_IP "${TAGS},ubuntu"