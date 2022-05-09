# Install Servers

## DNS Server

```bash
wget --no-cache -qO - https://raw.githubusercontent.com/taylor-training/proxmox/main/systems/dns-server.sh | sudo bash
```

## Ubuntu Server

```bash
wget --no-cache -qO - https://raw.githubusercontent.com/taylor-training/proxmox/main/systems/ubuntu-server.sh | sudo bash -s hostname host-ip
```