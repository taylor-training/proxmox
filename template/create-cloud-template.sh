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
    echo "Usage: $0 <distro> [template_id_override]"
    echo "Supported distros: $(list_supported_distros)"
    echo "Environment toggles: VERIFY_IMAGE_CHECKSUM=true|false, VERIFY_IMAGE_GPG=true|false, VALIDATE_SETUP_CONF=true|false"
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
if [ -z "${DISTRO}" ]; then
    usage
    exit 1
fi

if ! get_distro_config "${DISTRO}"; then
    exit 1
fi

TEMPLATE_ID="${2:-${DISTRO_TEMPLATE_ID}}"

echo "Preparing ${DISTRO_KEY} template ${DISTRO_VM_NAME}-Template (ID: ${TEMPLATE_ID})"

VALIDATE_SETUP_CONF="${VALIDATE_SETUP_CONF:-true}"
if is_enabled "${VALIDATE_SETUP_CONF}"; then
    "${SCRIPT_DIR}/validate-setup-conf.sh" --distro "${DISTRO}" --template-id "${TEMPLATE_ID}" --expect-template-missing
else
    echo "Skipping setup.conf validation (VALIDATE_SETUP_CONF=${VALIDATE_SETUP_CONF})"
fi

if ! "${SCRIPT_DIR}/verify-image-url.sh" "${DISTRO}"; then
    echo "Image URL check failed for ${DISTRO}, aborting template creation"
    exit 1
fi

make_auth_keys || true
download_image "${DISTRO_IMAGE_URL}" "${DISTRO_IMAGE_NAME}"

VERIFY_IMAGE_CHECKSUM="${VERIFY_IMAGE_CHECKSUM:-true}"
VERIFY_IMAGE_GPG="${VERIFY_IMAGE_GPG:-false}"

VERIFY_ARGS=()
if is_enabled "${VERIFY_IMAGE_GPG}"; then
    VERIFY_ARGS+=("--gpg")
fi
if ! is_enabled "${VERIFY_IMAGE_CHECKSUM}"; then
    VERIFY_ARGS+=("--no-checksum")
fi

if [ "${#VERIFY_ARGS[@]}" -gt 0 ] || is_enabled "${VERIFY_IMAGE_CHECKSUM}"; then
    "${SCRIPT_DIR}/verify-image-integrity.sh" "${DISTRO}" "${IMAGE_DIR:-$HOME/images}/${DISTRO_IMAGE_NAME}" "${VERIFY_ARGS[@]}"
fi

create_template "${TEMPLATE_ID}" "${DISTRO_VM_NAME}" "${DISTRO_IMAGE_NAME}" true "${DISTRO_TAGS}"

echo "Template build complete for ${DISTRO_KEY}"