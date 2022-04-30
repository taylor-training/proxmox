#!/bin/bash

ME=`whoami`

if [ "$ME" ne "root" ]; then 
    echo "You are not root, please sudo or become root"
    exit 1
fi

echo "Make sure swap line is commented out in /etc/fstab"

echo "Turning off swap - especially needed for k8s systems"
swapoff -a

if [ -e /swap.img ]; then
    echo "Removing swap image"
    rm -vf /swap.img
fi 

echo "Attempting to isntall QEMU Guest agent"
apt-get install -y qemu-guest-agent

echo "Updating apt packages"
apt-get update
apt-get upgrade -y

apt-get autoremove -y 
apt-get clean

echo "Reset cloud init"
cloud-init clean --logs

truncate -s 0 /etc/machine-id

cd /etc/ssh
rm -vf ssh_host_*

echo "Post script steps:"
echo " - Enable Agent"
echo " - Remove CD-ROM device"
echo " - Add Serial Port device (Hardware)"
echo " - Add Cloud init device (Hardware)"
echo " - Configure Cloud init"
echo "See README file for more details."


echo "Shutting down system in 2 mintes. Please stand-by."
shutdown -h +2 "Make Template"