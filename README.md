# Proxmox

Configurations, scripts and stuff for Proxmox VE server and supporting client VMs

## Setup scripts

Setup entrypoints now live at project root:

- `./setup-template.sh` writes `template/setup.conf`
- `./setup-systems.sh` writes `systems/setup.conf`

Compatibility wrappers still exist at `template/setup.sh` and `systems/setup.sh`.

## VM creation scripts

VM clone entrypoints now live in `systems/`:

- `./systems/create-vm-from-template.sh`
- `./systems/*-server.sh` per-distro wrappers

Compatibility wrappers remain in `template/` for older command paths.

## Sync files to Proxmox host

Use the root-level sync helper to push this project folder to your Proxmox server without setting up Git on the server:

```bash
./sync-to-proxmox.sh
```

Defaults:

- Host: `192.168.50.60`
- SSH user: `root`
- Remote path: `~`

With this default, top-level scripts land directly in your home directory on Proxmox (for example `~/combine-keys.sh`).

Override host (first argument):

```bash
./sync-to-proxmox.sh 192.168.50.70
```

Override host and remote path:

```bash
./sync-to-proxmox.sh root@192.168.50.70 proxmox-scripts
./sync-to-proxmox.sh root@192.168.50.70 /root/proxmox-scripts
```

Remote path behavior:

- Absolute path (`/root/proxmox-scripts`) syncs to that exact location.
- Home-relative path (`proxmox-scripts` or `~/proxmox-scripts`) syncs under the remote user's home.

Optional flags:

- `--dry-run` shows what would change
- `--delete` removes remote files that no longer exist locally

Windows Git Bash note:

- If `rsync` is unavailable in Git Bash, the script automatically falls back to `tar` over `ssh`.
- In fallback mode, `--delete` is not supported.
- To install `rsync` on Windows, install MSYS2 and run in an MSYS2 shell:

```bash
pacman -Syu
pacman -S rsync
```

## Create common cloud-init network snippet

Generate `configs/common/network-data.yaml` for the cloud-init profile workflow:

```bash
./create-network-snippet.sh
```

Defaults:

- Interface pattern: `ens18`
- DHCPv4: `true`
- DHCPv6: `true`
- Output file: `./configs/common/network-data.yaml`

If `template/setup.conf` exists, `NAME_SERVERS` and `SEARCH_DOMAIN` are used as prompt defaults.

Non-interactive example:

```bash
./create-network-snippet.sh --nameservers "192.168.50.10 1.1.1.1" --search-domains "homelab.local" --non-interactive --force
```
