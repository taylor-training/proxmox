# Proxmox

Configurations, scripts and stuff for Proxmox VE server and supporting client VMs

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
