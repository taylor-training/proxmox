#!/bin/bash

cd /etc/apt/sources.list.d

echo "# deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise" > pve-enterprise.list
echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" > pve-no-subscription.list

cd

apt-get update -y
apt-get install -y pve-kernel-5.15

sleep 5

apt-mark hold pve-kernel-5.11*
apt-mark hold pve-kernel-5.13*

sleep 5

apt-get upgrade -y

sleep 5

apt-get distro-upgrade -y

sleep 5

shutdown -r now