# Install Servers

## Setup Config

Generate `systems/setup.conf` from project root:

```bash
sudo ../../setup-systems.sh
```

Compatibility wrapper also works:

```bash
sudo ./setup.sh
```

## Ubuntu Server

```bash
wget --no-cache -qO - https://raw.githubusercontent.com/taylor-training/proxmox/main/systems/old/ubuntu-server.sh | sudo bash -s hostname host-ip
```

## DNS Server

```bash
wget --no-cache -qO - https://raw.githubusercontent.com/taylor-training/proxmox/main/systems/old/dns-server.sh | sudo bash -s hostname host-ip
```

## K3S Server

```bash
wget --no-cache -qO - https://raw.githubusercontent.com/taylor-training/proxmox/main/systems/old/k3s-server.sh | sudo bash -s hostname host-ip
```
