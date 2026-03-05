# Proxmox Cloud Templates

Scripts in this folder build Proxmox cloud templates for Ubuntu, Fedora, Debian, Rocky, AlmaLinux, and Arch, then create VM instances from those templates.

## 1) Initial setup

Run once to create `setup.conf` with your defaults:

```bash
sudo ./setup.sh
```

`setup.sh` writes `setup.conf` in this same folder and the other template scripts load it automatically.

### `setup.sh` prompts and example values

| Prompt | Example | Used as | Notes |
| --- | --- | --- | --- |
| `User:` | `jason` | `VM_USER` | Default cloud-init user for templates/cloned VMs |
| `Pass:` | `use-a-strong-pass` | `VM_PASS` | Password used for cloud-init in cloned VMs |
| `Cores:` | `2` | `VM_CORES` | Default vCPU count |
| `Memory (in GB):` | `4` | `VM_MEMORY=4096` | Script converts GB to MB |
| `Storage Device:` | `local-lvm` | `VM_DEVICE` | Proxmox storage name for disks/cloud-init |
| `Default VM disk space (in GB):` | `40` | `VM_SPACE=40G` | Clone/template disk resize target |
| `SSH Keys Filename:` | `auth.keys` | `SSHKEYS_FILE` | Combined key file path becomes `/root/auth.keys` |
| `Network Address (First Three Sets):` | `192.168.50` | `VM_NETWORK` | Used for static clone IPs like `192.168.50.41` |
| `Search Domain:` | `homelab.local` | `SEARCH_DOMAIN` | Saved for network/system scripts |
| `NameServers (separate entries with a space):` | `192.168.50.10 1.1.1.1` | `NAME_SERVERS` | Saved for network/system scripts |
| `Template Starting ID:` | `9000` | `TEMPLATE_ID_START` | Base template ID for distro offsets |

Template IDs are derived from `TEMPLATE_ID_START`:

- `ubuntu`: `+0`
- `fedora`: `+10`
- `debian`: `+20`
- `rocky`: `+30`
- `alma`: `+40`
- `arch`: `+50`

### Example `setup.conf`

```bash
VM_USER=jason
VM_PASS=use-a-strong-pass
VM_CORES=2
VM_MEMORY=4096
VM_DEVICE=local-lvm
VM_SPACE=40G
SSHKEYS_FILE=auth.keys
VM_NETWORK=192.168.50
SEARCH_DOMAIN=homelab.local
NAME_SERVERS=192.168.50.10 1.1.1.1
TEMPLATE_ID_START=9000
VERIFY_IMAGE_CHECKSUM=true
VERIFY_IMAGE_GPG=false
```

If `SSHKEYS_FILE` does not exist yet, template creation continues and uses password-based access until you add keys.

## 2) Build templates

### Verify image URLs (optional or standalone)

Check all catalog distro URLs:

```bash
sudo ./verify-image-url.sh
```

Check specific distros:

```bash
sudo ./verify-image-url.sh ubuntu rocky arch
```

### Verify downloaded image integrity (checksum / optional GPG)

After an image is downloaded, you can verify checksum integrity directly:

```bash
sudo ./verify-image-integrity.sh ubuntu
sudo ./verify-image-integrity.sh arch --gpg
```

You can also verify a specific file path:

```bash
sudo ./verify-image-integrity.sh debian /root/images/Debian-12.qcow2
```

### Generic template builder

```bash
sudo ./create-cloud-template.sh <distro>
```

`create-cloud-template.sh` runs URL validation automatically for the selected distro before download/import.

`create-cloud-template.sh` also runs checksum verification by default after download.

Control integrity checks with environment toggles:

```bash
sudo VERIFY_IMAGE_CHECKSUM=true VERIFY_IMAGE_GPG=false ./create-cloud-template.sh rocky
sudo VERIFY_IMAGE_CHECKSUM=true VERIFY_IMAGE_GPG=true ./create-cloud-template.sh ubuntu
```

You can persist those defaults in `setup.conf` (`VERIFY_IMAGE_CHECKSUM` and `VERIFY_IMAGE_GPG`).

Note: GPG verification requires the relevant distro signing keys to already exist in the Proxmox host GPG keyring.
If a distro does not publish signature metadata in the catalog entry, checksum verification still runs but GPG verification is skipped.

Supported distro keys:

- `ubuntu`
- `fedora`
- `debian`
- `rocky`
- `alma`
- `arch`

Example:

```bash
sudo ./create-cloud-template.sh ubuntu
```

### Per-distro wrappers

- `sudo ./ubuntu-cloud-template.sh`
- `sudo ./fedora-cloud-template.sh`
- `sudo ./debian-cloud-template.sh`
- `sudo ./rocky-cloud-template.sh`
- `sudo ./alma-cloud-template.sh`
- `sudo ./arch-cloud-template.sh`

## 3) Create VMs from templates

### Generic VM creator

```bash
sudo ./create-vm-from-template.sh <distro> <vm_name> [ipv4_last_octet] [extra_tags]
```

Examples:

```bash
sudo ./create-vm-from-template.sh ubuntu web-01 41 prod
sudo ./create-vm-from-template.sh fedora ci-runner 55 build
sudo ./create-vm-from-template.sh debian dns-01 53 infra
sudo ./create-vm-from-template.sh rocky app-01 61 prod
sudo ./create-vm-from-template.sh alma db-01 62 data
sudo ./create-vm-from-template.sh arch build-01 63 ci
```

### Per-distro wrappers

- `sudo ./ubuntu-server.sh <vm_name> [ipv4_last_octet] [extra_tags]`
- `sudo ./fedora-server.sh <vm_name> [ipv4_last_octet] [extra_tags]`
- `sudo ./debian-server.sh <vm_name> [ipv4_last_octet] [extra_tags]`
- `sudo ./rocky-server.sh <vm_name> [ipv4_last_octet] [extra_tags]`
- `sudo ./alma-server.sh <vm_name> [ipv4_last_octet] [extra_tags]`
- `sudo ./arch-server.sh <vm_name> [ipv4_last_octet] [extra_tags]`

## Adding another distro

Add one case entry in `distro-catalog.sh` with:

- Image URL and filename
- Template naming
- Template ID offset from `TEMPLATE_ID_START`
- Default tags

After that, you can immediately use:

```bash
sudo ./create-cloud-template.sh <new-distro-key>
sudo ./create-vm-from-template.sh <new-distro-key> <vm_name>
```