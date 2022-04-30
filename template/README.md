# Proxmox Templates

## Ubuntu Server Template

This has been tested with Ubuntu 22.04 LTS. Other versions may work but not validated.

### Virtual Machine Setup

Create an Ubuntu server.

 * General:
    * VM ID: 9000 (or something high for templates)
    * Name: Ubuntu-Server-Template
 * OS:
    * Use ISO: Select Ubuntu server iso file
 * System (all defaults)
 * Disks:
    * Device: VirtIO Block
    * Storage: local-lvm
    * Disk size: 20 (can be 10 if expanded later)
 * CPU (all defaults)
 * Memory (all defaults)
 * Network (defaults)


### Ubuntu Installation

Standard installation process:

 * Install SSH Server       

### Setup Script

 * `sudo nano /etc/fstab` and comment out swap line

 Run following script:

```bash
wget --no-cache -qO - https://raw.githubusercontent.com/taylor-training/proxmox/main/template/ubuntu-server-setup.sh | sudo bash
``` 

### Hardware Configuration

Post script steps:

 - Enable Agent
 - Remove CD-ROM device
 - Add Serial Port device (Hardware)
 - Add Cloud init device (Hardware)
 - Configure Cloud init