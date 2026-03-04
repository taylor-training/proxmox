#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_CONF="${SCRIPT_DIR}/setup.conf"

if [ ! -f "${SETUP_CONF}" ]; then
    echo "Unable to find setup file at ${SETUP_CONF}"
    exit 1
fi

source "${SETUP_CONF}"
source "${SCRIPT_DIR}/proxmox-lib.sh"
source "${SCRIPT_DIR}/distro-catalog.sh"

usage() {
    echo "Usage: $0 <distro> <vm_name> [ipv4_last_octet] [extra_tags]"
    echo "Supported distros: $(list_supported_distros)"
}

require_root

DISTRO="${1:-}"
VM_NAME="${2:-}"
VM_IP="${3:-}"
EXTRA_TAGS="${4:-}"

if [ -z "${DISTRO}" ] || [ -z "${VM_NAME}" ]; then
    usage
    exit 1
fi

if ! get_distro_config "${DISTRO}"; then
    exit 1
fi

NEXT_ID="$(pvesh get /cluster/nextid)"
VM_TAGS="${DISTRO_TAGS}"

if [ -n "${EXTRA_TAGS}" ]; then
    VM_TAGS="${VM_TAGS},${EXTRA_TAGS}"
fi

echo "Creating VM ${VM_NAME} (ID: ${NEXT_ID}) from template ${DISTRO_TEMPLATE_ID}"
clone_template "${DISTRO_TEMPLATE_ID}" "${NEXT_ID}" "${VM_NAME}" "${VM_IP}" "${VM_TAGS}"

echo "VM ${VM_NAME} created with ID ${NEXT_ID}"