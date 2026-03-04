#!/bin/bash

list_supported_distros() {
    echo "ubuntu fedora debian rocky alma arch"
}

get_distro_config() {
    local distro_key="${1,,}"

    DISTRO_KEY=""
    DISTRO_VM_NAME=""
    DISTRO_IMAGE_URL=""
    DISTRO_IMAGE_NAME=""
    DISTRO_SOURCE_IMAGE_NAME=""
    DISTRO_TEMPLATE_OFFSET=""
    DISTRO_TEMPLATE_ID=""
    DISTRO_TAGS=""
    DISTRO_CHECKSUM_URL=""
    DISTRO_CHECKSUM_SIG_URL=""
    DISTRO_CHECKSUM_CLEARSIGNED="false"

    case "${distro_key}" in
        ubuntu|ubuntu-lts|ubuntu-24.04|noble)
            DISTRO_KEY="ubuntu"
            DISTRO_VM_NAME="Ubuntu-LTS"
            DISTRO_IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
            DISTRO_IMAGE_NAME="Ubuntu-LTS-Server.img"
            DISTRO_SOURCE_IMAGE_NAME="noble-server-cloudimg-amd64.img"
            DISTRO_TEMPLATE_OFFSET=0
            DISTRO_TAGS="ubuntu,ubuntu-lts,24.04"
            DISTRO_CHECKSUM_URL="https://cloud-images.ubuntu.com/noble/current/SHA256SUMS"
            DISTRO_CHECKSUM_SIG_URL="https://cloud-images.ubuntu.com/noble/current/SHA256SUMS.gpg"
            ;;
        fedora|fedora-40|fedora-42)
            DISTRO_KEY="fedora"
            DISTRO_VM_NAME="Fedora-42"
            DISTRO_IMAGE_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/42/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-42-1.1.x86_64.qcow2"
            DISTRO_IMAGE_NAME="Fedora-42.qcow2"
            DISTRO_SOURCE_IMAGE_NAME="Fedora-Cloud-Base-Generic-42-1.1.x86_64.qcow2"
            DISTRO_TEMPLATE_OFFSET=10
            DISTRO_TAGS="fedora,fedora-42"
            DISTRO_CHECKSUM_URL="https://download.fedoraproject.org/pub/fedora/linux/releases/42/Cloud/x86_64/images/Fedora-Cloud-42-1.1-x86_64-CHECKSUM"
            DISTRO_CHECKSUM_CLEARSIGNED="true"
            ;;
        debian|debian-12|bookworm)
            DISTRO_KEY="debian"
            DISTRO_VM_NAME="Debian-12"
            DISTRO_IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
            DISTRO_IMAGE_NAME="Debian-12.qcow2"
            DISTRO_SOURCE_IMAGE_NAME="debian-12-genericcloud-amd64.qcow2"
            DISTRO_TEMPLATE_OFFSET=20
            DISTRO_TAGS="debian,debian-12,bookworm"
            DISTRO_CHECKSUM_URL="https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS"
            ;;
        rocky|rocky-9)
            DISTRO_KEY="rocky"
            DISTRO_VM_NAME="Rocky-9"
            DISTRO_IMAGE_URL="https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2"
            DISTRO_IMAGE_NAME="Rocky-9.qcow2"
            DISTRO_SOURCE_IMAGE_NAME="Rocky-9-GenericCloud.latest.x86_64.qcow2"
            DISTRO_TEMPLATE_OFFSET=30
            DISTRO_TAGS="rocky,rocky-9"
            DISTRO_CHECKSUM_URL="https://dl.rockylinux.org/pub/rocky/9/images/x86_64/CHECKSUM"
            DISTRO_CHECKSUM_SIG_URL="https://dl.rockylinux.org/pub/rocky/9/images/x86_64/CHECKSUM.asc"
            ;;
        alma|almalinux|alma-9)
            DISTRO_KEY="alma"
            DISTRO_VM_NAME="AlmaLinux-9"
            DISTRO_IMAGE_URL="https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
            DISTRO_IMAGE_NAME="AlmaLinux-9.qcow2"
            DISTRO_SOURCE_IMAGE_NAME="AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
            DISTRO_TEMPLATE_OFFSET=40
            DISTRO_TAGS="alma,almalinux,alma-9"
            DISTRO_CHECKSUM_URL="https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/CHECKSUM"
            DISTRO_CHECKSUM_SIG_URL="https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/CHECKSUM.asc"
            ;;
        arch|archlinux|arch-latest)
            DISTRO_KEY="arch"
            DISTRO_VM_NAME="Arch-Linux"
            DISTRO_IMAGE_URL="https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
            DISTRO_IMAGE_NAME="Arch-Linux.qcow2"
            DISTRO_SOURCE_IMAGE_NAME="Arch-Linux-x86_64-cloudimg.qcow2"
            DISTRO_TEMPLATE_OFFSET=50
            DISTRO_TAGS="arch,archlinux"
            DISTRO_CHECKSUM_URL="https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2.SHA256"
            DISTRO_CHECKSUM_SIG_URL="https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2.SHA256.sig"
            ;;
        *)
            echo "Unsupported distro key: ${1}"
            echo "Supported distros: $(list_supported_distros)"
            return 1
            ;;
    esac

    DISTRO_TEMPLATE_ID=$((TEMPLATE_ID_START + DISTRO_TEMPLATE_OFFSET))
}