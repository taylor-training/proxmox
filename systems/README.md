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

## Cluster recreation scripts

Two convenience scripts are provided to recreate the stage and prod k3s clusters by
destroying matching VMs (tagged with `stage` or `prod`) and then recreating them
from the per-distro wrappers.

- `../stage-k3s.sh` — recreate the stage cluster
- `../prod-k3s.sh` — recreate the prod cluster

Both scripts support the following flags:

- `-n, --dry-run`: list matching VMIDs and exit without destroying anything.
- `-y, --confirm`: skip the interactive confirmation prompt and proceed.

Both scripts require the helper utilities in this folder to be present:

- `utils/find-vmids-by-tag.sh` — used to find VMIDs by tag/name substring
- `utils/shutdown-vms.sh` — gracefully shuts down and destroys VMIDs

Recommended workflow:

1. Run a dry-run to confirm which VMs would be affected:

```bash
./prod-k3s.sh --dry-run
./stage-k3s.sh --dry-run
```

2. When satisfied, run with confirmation or use `--confirm` to skip prompts:

```bash
sudo ./prod-k3s.sh --confirm
sudo ./stage-k3s.sh --confirm
```

Notes:

- These scripts are destructive: ensure you have backups or snapshots if you need
	to preserve data from the VMs being destroyed.
- Run them from the project root or the `proxmox/` folder so relative paths to
	helpers resolve correctly.
