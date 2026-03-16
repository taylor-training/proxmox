#!/bin/bash

set -e

./sync-to-proxmox.sh 192.168.50.99 --delete
./sync-to-proxmox.sh 192.168.50.96 --delete
./sync-to-proxmox.sh 192.168.50.95 --delete