# Proxmox 7.x Setup

## Install on HX90 Mini PC

* Download Proxmox 7.0 ISO
* Burn to USB Key or use Vintoy
* Boot into USB Key (make sure BIOS will boot to USB)
* Select Proxmox 7.0 installer
* Walk through install process
* Open Terminal on other system to ssh to root@<IP>
* Run setup.sh script: `wget -qO - https://raw.githubusercontent.com/awesomejt/proxmox/main/server/setup.sh | bash` 
* Reboot server: `shutdown -r now`
* Make sure server boots with PVE kernel 5.15: `uname -a`
* Run upgrade.sh script: `wget -qO - https://raw.githubusercontent.com/awesomejt/proxmox/main/server/upgrade.sh | bash`
* Mark hold (exclude) pve kernel packages: 
  * `apt-mark hold pve-kernel-5.11*`
  * `apt-mark hold pve-kernel-5.13*`
* Update all other packages: `apt-get upgrade -y`
* Update distro to next release: `apt-get distro-upgrade -y`
* Reboot server: `shutdown -r now` for final time
* Login to web interface: `https://<IP>:8006/`
* Make sure on latest version of Proxmox

### Notes

* detect VM client status in Ubuntu: `systemd-detect-virt`  -  returns "kvm" in Qemu VMs in Proxmox