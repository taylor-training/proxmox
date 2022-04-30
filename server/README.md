# Proxmox 7.x Setup

## Install on HX90 Mini PC

* Download Proxmox 7.0 ISO
* Burn to USB Key or use Vintoy
* Boot into USB Key (make sure BIOS will boot to USB)
* Select Proxmox 7.0 installer
* Walk through install process
* Open Terminal on other system to ssh to root@<IP>
* Run setup.sh script: `wget -qO - https://raw.githubusercontent.com/taylor-training/proxmox/main/server/setup.sh | bash` 
* Wait for reboot, re-login
* Login to web interface: `https://<IP>:8006/`
* Make sure on latest version of Proxmox

### Notes

* detect VM client status in Ubuntu: `systemd-detect-virt`  -  returns "kvm" in Qemu VMs in Proxmox