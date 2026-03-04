# Proxmox Cloud Templates

Scripts in this folder build Proxmox cloud templates for Ubuntu, Fedora, Debian, Rocky, AlmaLinux, and Arch, then create VM instances from those templates.

## 1) Initial setup

Run once to create `setup.conf` with your defaults:

```bash
sudo ./setup.sh
```

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