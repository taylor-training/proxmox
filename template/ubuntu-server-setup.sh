#!/bin/bash

ME=`whoami`

if [ "$ME" ne "root" ]; then 
    echo "You are not root, please sudo or become root"
    exit 1
fi

echo "Make sure swap line is commented out in /etc/fstab"

swapoff -a 
rm -vf /swap.img

apt-get install -y qemu-guest-agent

apt-get update
apt-get upgrade -y

apt-get autoremove -y 
apt-get clean

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