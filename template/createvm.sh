#!/bin/bash

ME=`whoami`

if [ "${ME}" -ne "root" ]; then
    echo "You are not root, please sudo or become root"
    exit 1
fi

VM_ID=$1
VM_NAME=$2
VM_IP=$3

# User settings
storage="storage-1"
username="jason"

# VM PARAMS
OS_TYPE=l26
VM_MEM=1024
VM_CORES=2

ssh_keyfile=~/auth.keys

echo "Creating template ${VM_NAME} (ID: ${VM_ID}) using image ${VM_IMAGE}"

qm create $VM_ID --name $VM_NAME --ostype $OS_TYPE

qm set $VM_ID --net0 virtio,bridge=vmbr0
qm set $VM_ID --agent enabled=1,fstrim_cloned_disks=1
qm set $VM_ID --serial0 socket --vga serial0
qm set $VM_ID --memory $VM_MEM --cores $VM_CORES --cpu host

# Cloud Init
qm set $VM_ID --ide2 ${storage}:cloudinit
qm set $VM_ID --ciuser ${username}
qm set $VM_ID --sshkeys ${ssh_keyfile}
qm set $VM_ID --ipconfig0 "ip6=auto,ip=192.168.50.${VM_IP}/32,gw=192.168.50.1"