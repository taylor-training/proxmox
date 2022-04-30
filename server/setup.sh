#!/bin/bash

cd /etc/apt/sources.list.d

echo "# deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise" > pve-enterprise.list
echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" > pve-no-subscription.list

cd

apt-get update -y
apt-get install pve-kernel-5.15
apt-mark hold pve-kernel-5.11*
apt-mark hold pve-kernel-5.13*
apt-get upgrade -y
apt-get distro-upgrade -y