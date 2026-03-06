# Proxmox Cloud Templates

Scripts in this folder build Proxmox cloud templates for Ubuntu (LTS and latest), Fedora, Debian, Rocky, AlmaLinux, Arch, and CentOS Stream, then create VM instances from those templates.

## 1) Initial setup

Run once to create `setup.conf` with your defaults:

```bash
sudo ./setup.sh
```

If you see errors like `cannot execute: required file not found`, `$'\r': command not found`, or `unexpected end of file`, your scripts likely have Windows `CRLF` line endings. Convert to Linux `LF` on the Proxmox host:

```bash
find . -type f -name "*.sh" -exec sed -i 's/\r$//' {} +
chmod +x ./*.sh
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
| `Cloud-init config root:` | `/root/configs` | `CLOUD_INIT_CONFIG_ROOT` | Root directory for common/system cloud-init profile files |
| `Cloud-init snippet storage:` | `local` | `CLOUD_INIT_SNIPPET_STORAGE` | Proxmox storage name used in `--cicustom` snippet references |
| `Cloud-init snippet directory:` | `/var/lib/vz/snippets` | `CLOUD_INIT_SNIPPET_DIR` | Filesystem path where composed snippet files are written |

Template IDs are derived from `TEMPLATE_ID_START`:

- `ubuntu` / `ubuntu-lts` (defaults to Ubuntu 24.04 LTS): `+0`
- `ubuntu-latest` (Ubuntu 25.10): `+1`
- `fedora` (defaults to Fedora 43): `+10`
- `debian`: `+20`
- `rocky` (defaults to Rocky 10.1): `+30`
- `alma` (defaults to AlmaLinux 10.1): `+40`
- `arch`: `+50`
- `centos` (Stream 10): `+70`

Legacy compatibility alias:

- `ubuntu-24.04` (`noble`): `+0`
- `fedora-42` (`fedora-40`): `+11`
- `rocky-9` (`r9`): `+31`
- `alma-9`: `+41`
- `debian-12` (`bookworm`): `+21`
- `centos-9-stream` (`c9s`): `+60`

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
CLOUD_INIT_CONFIG_ROOT=/root/configs
CLOUD_INIT_SNIPPET_STORAGE=local
CLOUD_INIT_SNIPPET_DIR=/var/lib/vz/snippets
VERIFY_IMAGE_CHECKSUM=true
VERIFY_IMAGE_GPG=false
VALIDATE_SETUP_CONF=true
```

If `SSHKEYS_FILE` does not exist yet, template creation continues and uses password-based access until you add keys.

You can generate both the legacy combined key file and a reusable cloud-init SSH section with:

```bash
sudo ../combine-keys.sh
```

By default this writes:

- `/root/auth.keys`
- `/root/configs/common/ssh-authorized-keys.yaml`

### Validate `setup.conf` against current Proxmox state

Run validation directly:

```bash
sudo ./validate-setup-conf.sh
```

Validate with distro-aware template expectations:

```bash
sudo ./validate-setup-conf.sh --distro ubuntu-lts --expect-template-missing
sudo ./validate-setup-conf.sh --distro ubuntu-lts --expect-template-exists --vm-ip 41
sudo ./validate-setup-conf.sh --distro ubuntu-lts --expect-template-exists --vm-ip 41 --cloud-init-profile web
```

The validator checks both config shape and live Proxmox state, including:

- Required `setup.conf` values are present and well-formed
- `VM_DEVICE` storage exists and supports `images`
- Bridge `vmbr0` exists
- Template ID exists/does not exist as expected for the action
- Optional warning when static VM IP appears to already be in use in existing VM `ipconfig0`
- When `--cloud-init-profile` is provided, snippet storage exists and supports `snippets`
- When `--cloud-init-profile` is provided, at least one expected cloud-init override file exists under `CLOUD_INIT_CONFIG_ROOT`

## 2) Build templates

### Verify image URLs (optional or standalone)

Check all catalog distro URLs:

```bash
sudo ./verify-image-url.sh
```

Check specific distros:

```bash
sudo ./verify-image-url.sh ubuntu-lts ubuntu-latest rocky arch
```

### Verify downloaded image integrity (checksum / optional GPG)

After an image is downloaded, you can verify checksum integrity directly:

```bash
sudo ./verify-image-integrity.sh ubuntu-lts
sudo ./verify-image-integrity.sh ubuntu-latest
sudo ./verify-image-integrity.sh arch --gpg
```

You can also verify a specific file path:

```bash
sudo ./verify-image-integrity.sh debian /root/images/Debian-13.qcow2
```

### Generic template builder

```bash
sudo ./create-cloud-template.sh <distro>
```

`create-cloud-template.sh` runs URL validation automatically for the selected distro before download/import.

`create-cloud-template.sh` also runs checksum verification by default after download.

Control integrity and validation checks with environment toggles:

```bash
sudo VERIFY_IMAGE_CHECKSUM=true VERIFY_IMAGE_GPG=false VALIDATE_SETUP_CONF=true ./create-cloud-template.sh rocky
sudo VERIFY_IMAGE_CHECKSUM=true VERIFY_IMAGE_GPG=true VALIDATE_SETUP_CONF=true ./create-cloud-template.sh ubuntu-lts
```

You can persist those defaults in `setup.conf` (`VERIFY_IMAGE_CHECKSUM`, `VERIFY_IMAGE_GPG`, and `VALIDATE_SETUP_CONF`).

Note: GPG verification requires the relevant distro signing keys to already exist in the Proxmox host GPG keyring.
If a distro does not publish signature metadata in the catalog entry, checksum verification still runs but GPG verification is skipped.

Supported distro keys:

- `ubuntu` (alias of `ubuntu-lts`)
- `ubuntu-lts` (Ubuntu 24.04 LTS)
- `ubuntu-latest` (Ubuntu 25.10)
- `fedora` (defaults to Fedora 43)
- `debian` (defaults to Debian 13)
- `rocky` (defaults to Rocky 10.1)
- `alma` (defaults to AlmaLinux 10.1)
- `arch`
- `centos` (defaults to Stream 10)

Example:

```bash
sudo ./create-cloud-template.sh ubuntu-lts
sudo ./create-cloud-template.sh ubuntu-latest
```

### Per-distro wrappers

- `sudo ./ubuntu-cloud-template.sh` (uses `ubuntu` / `ubuntu-lts`)
- `sudo ./ubuntu-latest-cloud-template.sh` (uses `ubuntu-latest`)
- `sudo ./fedora-cloud-template.sh`
- `sudo ./debian-cloud-template.sh`
- `sudo ./rocky-cloud-template.sh`
- `sudo ./alma-cloud-template.sh`
- `sudo ./arch-cloud-template.sh`
- `sudo ./centos-cloud-template.sh`

## 3) Create VMs from templates

### Generic VM creator

```bash
sudo ./create-vm-from-template.sh <distro> <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]
```

`create-vm-from-template.sh` runs `setup.conf` validation by default. Set `VALIDATE_SETUP_CONF=false` to skip.

If `--cloud-init` is not provided, the script auto-selects from `~/configs/systems/*.user-data.yaml` using this precedence:

- Exact distro argument (for example `ubuntu-latest.user-data.yaml`)
- Canonical distro key from catalog
- Base distro family (for example `ubuntu.user-data.yaml`)

This allows variants like `ubuntu-latest` or `ubuntu-lts` to fall back to `ubuntu.user-data.yaml` when variant-specific files are absent.

Examples:

```bash
sudo ./create-vm-from-template.sh ubuntu web-01 41 prod
sudo ./create-vm-from-template.sh ubuntu web-02 42 prod --cloud-init web
sudo ./create-vm-from-template.sh ubuntu-latest web-edge-01 42 prod
sudo ./create-vm-from-template.sh fedora ci-runner 55 build
sudo ./create-vm-from-template.sh fedora-42 ci-legacy-01 56 build
sudo ./create-vm-from-template.sh debian dns-01 53 infra
sudo ./create-vm-from-template.sh debian-12 dns-legacy-01 54 infra
sudo ./create-vm-from-template.sh rocky app-01 61 prod
sudo ./create-vm-from-template.sh rocky-9 app-legacy-01 62 prod
sudo ./create-vm-from-template.sh alma db-01 63 data
sudo ./create-vm-from-template.sh alma-9 db-legacy-01 64 data
sudo ./create-vm-from-template.sh arch build-01 65 ci
sudo ./create-vm-from-template.sh centos stream10-01 66 infra
sudo ./create-vm-from-template.sh centos-9-stream stream9-01 67 legacy
```

### Optional cloud-init profile conventions

When `--cloud-init <profile_name>` is provided, VM creation composes and applies `--cicustom` snippets using convention-based paths rooted at `~/configs` by default.

When `--cloud-init` is omitted, VM creation attempts the auto-selection precedence above and uses the first matching profile file found.

Environment overrides:

- `CLOUD_INIT_CONFIG_ROOT` (default: `~/configs`)
- `CLOUD_INIT_SNIPPET_STORAGE` (default: `local`)
- `CLOUD_INIT_SNIPPET_DIR` (default: `/var/lib/vz/snippets`)

Profile file conventions:

- Common user-data: `~/configs/common/user-data.yaml`
- Common SSH fragment: `~/configs/common/ssh-authorized-keys.yaml`
- Common network-data: `~/configs/common/network-data.yaml`
- Common meta-data: `~/configs/common/meta-data.yaml`
- System user-data: `~/configs/systems/<profile_name>.user-data.yaml`
- System network-data: `~/configs/systems/<profile_name>.network-data.yaml`
- System meta-data: `~/configs/systems/<profile_name>.meta-data.yaml`

Helper scripts in repo root can generate common snippets:

- `../combine-keys.sh` writes `~/configs/common/ssh-authorized-keys.yaml`
- `../create-network-snippet.sh` writes `~/configs/common/network-data.yaml`

Composition behavior:

- User-data starts from Proxmox-generated cloud-init user-data for the new VM, then adds: common user-data, common SSH fragment, then system user-data.
- Network-data prefers system file, then common file.
- Meta-data prefers system file, then common file.

If no profile-specific overrides are found for the selected profile, VM creation fails fast with expected paths.

### Per-distro wrappers

- `sudo ./ubuntu-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]` (uses `ubuntu` / `ubuntu-lts`)
- `sudo ./ubuntu-latest-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]` (uses `ubuntu-latest`)
- `sudo ./fedora-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./debian-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./rocky-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./alma-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./arch-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`
- `sudo ./centos-server.sh <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]`

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