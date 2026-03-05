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
    echo "Environment toggles: VALIDATE_SETUP_CONF=true|false"
}

is_enabled() {
    case "${1,,}" in
        1|true|yes|on)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
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

VALIDATE_SETUP_CONF="${VALIDATE_SETUP_CONF:-true}"
if is_enabled "${VALIDATE_SETUP_CONF}"; then
    VALIDATION_ARGS=(--distro "${DISTRO}" --template-id "${DISTRO_TEMPLATE_ID}" --expect-template-exists)
    if [ -n "${VM_IP}" ]; then
        VALIDATION_ARGS+=(--vm-ip "${VM_IP}")
    fi
    "${SCRIPT_DIR}/validate-setup-conf.sh" "${VALIDATION_ARGS[@]}"
else
    echo "Skipping setup.conf validation (VALIDATE_SETUP_CONF=${VALIDATE_SETUP_CONF})"
fi

NEXT_ID="$(pvesh get /cluster/nextid)"
VM_TAGS="${DISTRO_TAGS}"

if [ -n "${EXTRA_TAGS}" ]; then
    VM_TAGS="${VM_TAGS},${EXTRA_TAGS}"
fi

echo "Creating VM ${VM_NAME} (ID: ${NEXT_ID}) from template ${DISTRO_TEMPLATE_ID}"
clone_template "${DISTRO_TEMPLATE_ID}" "${NEXT_ID}" "${VM_NAME}" "${VM_IP}" "${VM_TAGS}"

echo "VM ${VM_NAME} created with ID ${NEXT_ID}"