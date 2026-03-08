# VM Creation Scripts

This folder now contains VM creation entrypoints that clone VMs from Proxmox templates.

## Generic VM creator

From project root:

```bash
sudo ./systems/create-vm-from-template.sh <distro> <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>] [--cpu <cores>] [--memory <mb>] [--disk <size>]
```

From inside this folder:

```bash
sudo ./create-vm-from-template.sh <distro> <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>] [--cpu <cores>] [--memory <mb>] [--disk <size>]
```

Optional resource override flags:

- `--cpu` / `-c`: CPU cores (positive integer)
- `--memory` / `-m`: memory in MB (positive integer)
- `--disk` / `-d`: disk size (for example `40G`, `10240M`, `1T`)

When omitted, values from `template/setup.conf` are used (`VM_CORES`, `VM_MEMORY`, `VM_SPACE`).

Examples:

```bash
sudo ./create-vm-from-template.sh ubuntu web-01 41 prod
sudo ./create-vm-from-template.sh ubuntu-latest web-edge-01 42 prod
sudo ./create-vm-from-template.sh debian dns-01 53 infra
sudo ./create-vm-from-template.sh rocky app-01 61 prod
sudo ./create-vm-from-template.sh ubuntu app-02 44 prod --cpu 4 --memory 8192 --disk 80G
```

By default, newly created VMs are started automatically. Set `AUTO_START_VM=false` to create the VM in a stopped state.

Cloud-init `network-data` overrides are disabled by default so Proxmox `ipconfig0` remains authoritative. Set `CLOUD_INIT_INCLUDE_NETWORK_DATA=true` only when you want profile-driven network config to override that behavior.

During VM creation, SSH key data is refreshed from `~/keys/*.pub` by default (`AUTO_REFRESH_SSH_KEYS=true`) so both `~/auth.keys` and `~/configs/common/ssh-authorized-keys.yaml` stay current. Set `AUTO_REFRESH_SSH_KEYS=false` to skip this refresh.

## Per-distro wrappers

All wrapper scripts accept the same optional flags (`--cloud-init`, `--cpu`, `--memory`, `--disk`) after the positional arguments.

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
