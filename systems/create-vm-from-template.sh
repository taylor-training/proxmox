#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${PROJECT_DIR}/template"
SETUP_CONF="${TEMPLATE_DIR}/setup.conf"

if [ ! -f "${SETUP_CONF}" ]; then
    echo "Unable to find setup file at ${SETUP_CONF}"
    exit 1
fi

source "${SETUP_CONF}"
source "${TEMPLATE_DIR}/proxmox-lib.sh"
source "${TEMPLATE_DIR}/distro-catalog.sh"

usage() {
    echo "Usage: $0 <distro> <vm_name> [ipv4_last_octet] [extra_tags] [--cloud-init <profile_name>]"
    echo "Supported distros: $(list_supported_distros)"
    echo "Default cloud-init behavior: if --cloud-init is omitted and ~/configs/systems/<distro>.user-data.yaml exists, that <distro> profile is used automatically"
    echo "Environment toggles: VALIDATE_SETUP_CONF=true|false, CLOUD_INIT_CONFIG_ROOT=~/configs, CLOUD_INIT_SNIPPET_STORAGE=local, CLOUD_INIT_SNIPPET_DIR=/var/lib/vz/snippets"
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
VM_IP=""
EXTRA_TAGS=""
CLOUD_INIT_PROFILE=""

if [ -z "${DISTRO}" ] || [ -z "${VM_NAME}" ]; then
    usage
    exit 1
fi

shift 2
while [ "$#" -gt 0 ]; do
    case "$1" in
        --cloud-init)
            if [ "$#" -lt 2 ]; then
                echo "Missing value for --cloud-init"
                usage
                exit 1
            fi
            CLOUD_INIT_PROFILE="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [ -z "${VM_IP}" ]; then
                VM_IP="$1"
            elif [ -z "${EXTRA_TAGS}" ]; then
                EXTRA_TAGS="$1"
            else
                echo "Unexpected argument: $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

if ! get_distro_config "${DISTRO}"; then
    exit 1
fi

if [ -z "${CLOUD_INIT_PROFILE}" ]; then
    CLOUD_INIT_PROFILE_ROOT="${CLOUD_INIT_CONFIG_ROOT:-$HOME/configs}"
    DISTRO_REQUESTED_PROFILE="${DISTRO,,}"
    DISTRO_DEFAULT_PROFILE="${DISTRO_TAGS%%,*}"
    CANDIDATE_PROFILES=("${DISTRO_REQUESTED_PROFILE}")

    if [ -z "${DISTRO_DEFAULT_PROFILE}" ]; then
        DISTRO_DEFAULT_PROFILE="${DISTRO_KEY}"
    fi

    if [ -n "${DISTRO_KEY}" ] && [ "${DISTRO_KEY}" != "${DISTRO_REQUESTED_PROFILE}" ]; then
        CANDIDATE_PROFILES+=("${DISTRO_KEY}")
    fi

    if [ -n "${DISTRO_DEFAULT_PROFILE}" ] \
        && [ "${DISTRO_DEFAULT_PROFILE}" != "${DISTRO_REQUESTED_PROFILE}" ] \
        && [ "${DISTRO_DEFAULT_PROFILE}" != "${DISTRO_KEY}" ]; then
        CANDIDATE_PROFILES+=("${DISTRO_DEFAULT_PROFILE}")
    fi

    for candidate_profile in "${CANDIDATE_PROFILES[@]}"; do
        DISTRO_DEFAULT_USER_DATA_FILE="${CLOUD_INIT_PROFILE_ROOT}/systems/${candidate_profile}.user-data.yaml"

        if [ -f "${DISTRO_DEFAULT_USER_DATA_FILE}" ]; then
            CLOUD_INIT_PROFILE="${candidate_profile}"
            echo "Auto-selecting cloud-init profile ${CLOUD_INIT_PROFILE} from ${DISTRO_DEFAULT_USER_DATA_FILE}"
            break
        fi
    done
fi

VALIDATE_SETUP_CONF="${VALIDATE_SETUP_CONF:-true}"
if is_enabled "${VALIDATE_SETUP_CONF}"; then
    VALIDATION_ARGS=(--distro "${DISTRO}" --template-id "${DISTRO_TEMPLATE_ID}" --expect-template-exists)
    if [ -n "${VM_IP}" ]; then
        VALIDATION_ARGS+=(--vm-ip "${VM_IP}")
    fi
    if [ -n "${CLOUD_INIT_PROFILE}" ]; then
        VALIDATION_ARGS+=(--cloud-init-profile "${CLOUD_INIT_PROFILE}")
    fi
    "${TEMPLATE_DIR}/validate-setup-conf.sh" "${VALIDATION_ARGS[@]}"
else
    echo "Skipping setup.conf validation (VALIDATE_SETUP_CONF=${VALIDATE_SETUP_CONF})"
fi

NEXT_ID="$(pvesh get /cluster/nextid)"
VM_TAGS="${DISTRO_TAGS}"

if [ -n "${EXTRA_TAGS}" ]; then
    VM_TAGS="${VM_TAGS},${EXTRA_TAGS}"
fi

echo "Creating VM ${VM_NAME} (ID: ${NEXT_ID}) from template ${DISTRO_TEMPLATE_ID}"
clone_template "${DISTRO_TEMPLATE_ID}" "${NEXT_ID}" "${VM_NAME}" "${VM_IP}" "${VM_TAGS}" "${CLOUD_INIT_PROFILE}"

echo "VM ${VM_NAME} created with ID ${NEXT_ID}"
