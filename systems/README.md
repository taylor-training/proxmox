# VM Creation Scripts

This folder now contains VM creation entrypoints that clone VMs from Proxmox templates.

## Generic VM creator

From project root:

```bash
sudo ./systems/create-vm-from-template.sh <distro> <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]
```

From inside this folder:

```bash
sudo ./create-vm-from-template.sh <distro> <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]
```

Examples:

```bash
sudo ./create-vm-from-template.sh ubuntu web-01 41 prod
sudo ./create-vm-from-template.sh ubuntu-latest web-edge-01 42 prod
sudo ./create-vm-from-template.sh debian dns-01 53 infra
sudo ./create-vm-from-template.sh rocky app-01 61 prod
```

## Per-distro wrappers

- `sudo ./ubuntu-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./ubuntu-latest-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./fedora-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./debian-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./rocky-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./alma-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./arch-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./centos-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`

## Legacy scripts

Legacy in-guest provisioning scripts previously in `systems/` were moved to `systems/old/`.
