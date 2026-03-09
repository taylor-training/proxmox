#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_CONF="${SCRIPT_DIR}/setup.conf"

usage() {
    echo "Usage: $0 [--distro <key>] [--template-id <id>] [--expect-template-missing|--expect-template-exists] [--vm-ip <last_octet>] [--cloud-init-profile <name>]"
    echo "Examples:"
    echo "  $0"
    echo "  $0 --distro ubuntu --expect-template-missing"
    echo "  $0 --distro ubuntu --expect-template-exists --vm-ip 41"
    echo "  $0 --distro ubuntu --expect-template-exists --vm-ip 41 --cloud-init-profile web"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

if [ ! -f "${SETUP_CONF}" ]; then
    echo "Unable to find setup file at ${SETUP_CONF}"
    exit 1
fi

source "${SETUP_CONF}"

ERROR_COUNT=0
WARN_COUNT=0

DISTRO=""
TEMPLATE_ID=""
TEMPLATE_EXPECTATION="ignore"
VM_IP=""
CLOUD_INIT_PROFILE=""

error() {
    echo "[ERROR] $*"
    ERROR_COUNT=$((ERROR_COUNT + 1))
}

warn() {
    echo "[WARN] $*"
    WARN_COUNT=$((WARN_COUNT + 1))
}

is_positive_int() {
    [[ "${1}" =~ ^[1-9][0-9]*$ ]]
}

is_boolean() {
    case "${1,,}" in
        1|0|true|false|yes|no|on|off)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

has_whitespace() {
    [[ "${1}" =~ [[:space:]] ]]
}

is_cloud_init_profile_name() {
    [[ "${1}" =~ ^[A-Za-z0-9._-]+$ ]]
}

is_ipv4() {
    local ip="$1"
    local o1 o2 o3 o4

    IFS='.' read -r o1 o2 o3 o4 <<< "${ip}"

    if [ -z "${o1}" ] || [ -z "${o2}" ] || [ -z "${o3}" ] || [ -z "${o4}" ]; then
        return 1
    fi

    for octet in "${o1}" "${o2}" "${o3}" "${o4}"; do
        if ! [[ "${octet}" =~ ^[0-9]+$ ]]; then
            return 1
        fi
        if [ "${octet}" -lt 0 ] || [ "${octet}" -gt 255 ]; then
            return 1
        fi
    done

    return 0
}

is_ipv6() {
    [[ "${1}" == *:* ]]
}

require_var() {
    local var_name="$1"
    local value="${!var_name:-}"

    if [ -z "${value}" ]; then
        error "Missing required ${var_name} in setup.conf"
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --distro)
            shift
            DISTRO="${1:-}"
            ;;
        --template-id)
            shift
            TEMPLATE_ID="${1:-}"
            ;;
        --expect-template-missing)
            TEMPLATE_EXPECTATION="missing"
            ;;
        --expect-template-exists)
            TEMPLATE_EXPECTATION="exists"
            ;;
        --vm-ip)
            shift
            VM_IP="${1:-}"
            ;;
        --cloud-init-profile)
            shift
            if [ -z "${1:-}" ]; then
                echo "Missing value for --cloud-init-profile"
                usage
                exit 1
            fi
            CLOUD_INIT_PROFILE="${1:-}"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac

    shift
done

echo "Validating setup.conf against Proxmox state"

require_var "VM_USER"
require_var "VM_PASS"
require_var "VM_CORES"
require_var "VM_MEMORY"
require_var "VM_DEVICE"
require_var "VM_SPACE"
require_var "SSHKEYS_FILE"
require_var "VM_NETWORK"
require_var "TEMPLATE_ID_START"

if [ -n "${VM_USER:-}" ] && ! [[ "${VM_USER}" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
    warn "VM_USER (${VM_USER}) is unusual for a Linux username"
fi

if [ -n "${VM_CORES:-}" ] && ! is_positive_int "${VM_CORES}"; then
    error "VM_CORES (${VM_CORES}) must be a positive integer"
fi

if [ -n "${VM_MEMORY:-}" ]; then
    if ! is_positive_int "${VM_MEMORY}"; then
        error "VM_MEMORY (${VM_MEMORY}) must be a positive integer in MB"
    elif [ "${VM_MEMORY}" -lt 512 ]; then
        warn "VM_MEMORY (${VM_MEMORY} MB) is very low"
    fi
fi

if [ -n "${VM_SPACE:-}" ]; then
    if ! [[ "${VM_SPACE}" =~ ^[1-9][0-9]*[MGT]$ ]]; then
        error "VM_SPACE (${VM_SPACE}) must look like 40G, 10240M, or 1T"
    fi
fi

template_base_disk_effective="${TEMPLATE_BASE_DISK:-10G}"
if ! [[ "${template_base_disk_effective}" =~ ^[1-9][0-9]*[MGT]$ ]]; then
    error "TEMPLATE_BASE_DISK (${template_base_disk_effective}) must look like 10G, 10240M, or 1T"
fi

if [ -n "${VM_NETWORK:-}" ]; then
    if ! [[ "${VM_NETWORK}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "VM_NETWORK (${VM_NETWORK}) must be first three IPv4 octets, like 192.168.50"
    else
        IFS='.' read -r net1 net2 net3 <<< "${VM_NETWORK}"
        for octet in "${net1}" "${net2}" "${net3}"; do
            if [ "${octet}" -lt 0 ] || [ "${octet}" -gt 255 ]; then
                error "VM_NETWORK (${VM_NETWORK}) has an invalid octet"
                break
            fi
        done
    fi
fi

if [ -n "${TEMPLATE_ID_START:-}" ] && ! is_positive_int "${TEMPLATE_ID_START}"; then
    error "TEMPLATE_ID_START (${TEMPLATE_ID_START}) must be a positive integer"
fi

for bool_var in VERIFY_IMAGE_CHECKSUM VERIFY_IMAGE_GPG VALIDATE_SETUP_CONF; do
    bool_value="${!bool_var:-}"
    if [ -n "${bool_value}" ] && ! is_boolean "${bool_value}"; then
        error "${bool_var} (${bool_value}) must be a boolean value"
    fi
done

CLOUD_INIT_CONFIG_ROOT_EFFECTIVE="${CLOUD_INIT_CONFIG_ROOT:-$HOME/configs}"
CLOUD_INIT_SNIPPET_STORAGE_EFFECTIVE="${CLOUD_INIT_SNIPPET_STORAGE:-local}"
CLOUD_INIT_SNIPPET_DIR_EFFECTIVE="${CLOUD_INIT_SNIPPET_DIR:-/var/lib/vz/snippets}"

if has_whitespace "${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}"; then
    error "CLOUD_INIT_CONFIG_ROOT (${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}) must not contain whitespace"
fi

if has_whitespace "${CLOUD_INIT_SNIPPET_STORAGE_EFFECTIVE}"; then
    error "CLOUD_INIT_SNIPPET_STORAGE (${CLOUD_INIT_SNIPPET_STORAGE_EFFECTIVE}) must not contain whitespace"
fi

if has_whitespace "${CLOUD_INIT_SNIPPET_DIR_EFFECTIVE}"; then
    error "CLOUD_INIT_SNIPPET_DIR (${CLOUD_INIT_SNIPPET_DIR_EFFECTIVE}) must not contain whitespace"
fi

if [[ "${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}" != /* ]]; then
    warn "CLOUD_INIT_CONFIG_ROOT (${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}) is not an absolute path"
fi

if [[ "${CLOUD_INIT_SNIPPET_DIR_EFFECTIVE}" != /* ]]; then
    warn "CLOUD_INIT_SNIPPET_DIR (${CLOUD_INIT_SNIPPET_DIR_EFFECTIVE}) is not an absolute path"
fi

if [ -n "${CLOUD_INIT_PROFILE}" ]; then
    if ! is_cloud_init_profile_name "${CLOUD_INIT_PROFILE}"; then
        error "--cloud-init-profile (${CLOUD_INIT_PROFILE}) may only contain letters, numbers, dots, underscores, and dashes"
    fi

    common_user_file="${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}/common/user-data.yaml"
    common_ssh_file="${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}/common/ssh-authorized-keys.yaml"
    common_network_file="${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}/common/network-data.yaml"
    common_meta_file="${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}/common/meta-data.yaml"
    system_user_file="${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}/systems/${CLOUD_INIT_PROFILE}.user-data.yaml"
    system_network_file="${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}/systems/${CLOUD_INIT_PROFILE}.network-data.yaml"
    system_meta_file="${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}/systems/${CLOUD_INIT_PROFILE}.meta-data.yaml"

    if command -v pvesm >/dev/null 2>&1; then
        if ! pvesm status -storage "${CLOUD_INIT_SNIPPET_STORAGE_EFFECTIVE}" >/dev/null 2>&1; then
            error "Cloud-init snippet storage (${CLOUD_INIT_SNIPPET_STORAGE_EFFECTIVE}) does not exist or is not available"
        else
            snippet_content="$(pvesm config "${CLOUD_INIT_SNIPPET_STORAGE_EFFECTIVE}" 2>/dev/null | awk '/^content / { print $2 }')"
            if [ -n "${snippet_content}" ] && ! printf ',%s,' "${snippet_content}" | grep -q ',snippets,'; then
                error "Cloud-init snippet storage (${CLOUD_INIT_SNIPPET_STORAGE_EFFECTIVE}) does not advertise 'snippets' content"
            fi
        fi
    fi

    if [ -d "${CLOUD_INIT_SNIPPET_DIR_EFFECTIVE}" ]; then
        if [ ! -w "${CLOUD_INIT_SNIPPET_DIR_EFFECTIVE}" ]; then
            error "CLOUD_INIT_SNIPPET_DIR (${CLOUD_INIT_SNIPPET_DIR_EFFECTIVE}) is not writable"
        fi
    else
        snippet_parent_dir="$(dirname "${CLOUD_INIT_SNIPPET_DIR_EFFECTIVE}")"
        if [ ! -d "${snippet_parent_dir}" ]; then
            warn "Parent directory for CLOUD_INIT_SNIPPET_DIR (${snippet_parent_dir}) does not exist"
        elif [ ! -w "${snippet_parent_dir}" ]; then
            error "Parent directory for CLOUD_INIT_SNIPPET_DIR (${snippet_parent_dir}) is not writable"
        fi
    fi

    cloud_init_override_found=0
    for candidate in \
        "${common_user_file}" \
        "${common_ssh_file}" \
        "${common_network_file}" \
        "${common_meta_file}" \
        "${system_user_file}" \
        "${system_network_file}" \
        "${system_meta_file}"; do
        if [ -f "${candidate}" ]; then
            cloud_init_override_found=1
            break
        fi
    done

    if [ "${cloud_init_override_found}" -eq 0 ]; then
        error "No cloud-init override files found for profile (${CLOUD_INIT_PROFILE}) under ${CLOUD_INIT_CONFIG_ROOT_EFFECTIVE}"
    fi
fi

if [ -n "${NAME_SERVERS:-}" ]; then
    for ns in ${NAME_SERVERS}; do
        if ! is_ipv4 "${ns}" && ! is_ipv6 "${ns}"; then
            warn "NameServer entry (${ns}) is not an IP literal"
        fi
    done
fi

for cmd in qm pvesm pvesh ip; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        error "Required command (${cmd}) not found"
    fi
done

if command -v pvesm >/dev/null 2>&1 && [ -n "${VM_DEVICE:-}" ]; then
    if ! pvesm status -storage "${VM_DEVICE}" >/dev/null 2>&1; then
        error "Storage (${VM_DEVICE}) does not exist or is not available"
    else
        storage_content="$(pvesm config "${VM_DEVICE}" 2>/dev/null | awk '/^content / { print $2 }')"
        if [ -n "${storage_content}" ] && ! printf ',%s,' "${storage_content}" | grep -q ',images,'; then
            error "Storage (${VM_DEVICE}) does not advertise 'images' content"
        fi
    fi
fi

if command -v ip >/dev/null 2>&1; then
    if ! ip link show vmbr0 >/dev/null 2>&1; then
        error "Bridge vmbr0 does not exist (scripts currently use vmbr0)"
    fi
fi

ssh_key_path="$HOME/${SSHKEYS_FILE:-}"
if [ -n "${SSHKEYS_FILE:-}" ] && [ ! -f "${ssh_key_path}" ]; then
    warn "SSH key file (${ssh_key_path}) not found; templates will use password auth"
elif [ -n "${SSHKEYS_FILE:-}" ] && [ ! -s "${ssh_key_path}" ]; then
    warn "SSH key file (${ssh_key_path}) is empty"
fi

if [ -n "${DISTRO}" ]; then
    if [ ! -f "${SCRIPT_DIR}/distro-catalog.sh" ]; then
        error "Unable to find distro-catalog.sh for distro validation"
    else
        source "${SCRIPT_DIR}/distro-catalog.sh"

        if ! get_distro_config "${DISTRO}" >/dev/null 2>&1; then
            error "Unsupported distro key (${DISTRO})"
        else
            effective_template_id="${TEMPLATE_ID:-${DISTRO_TEMPLATE_ID}}"

            if ! is_positive_int "${effective_template_id}"; then
                error "Template ID (${effective_template_id}) must be a positive integer"
            else
                if [ "${TEMPLATE_EXPECTATION}" = "missing" ]; then
                    if qm status "${effective_template_id}" >/dev/null 2>&1; then
                        error "Template/VM ID (${effective_template_id}) already exists"
                    fi
                elif [ "${TEMPLATE_EXPECTATION}" = "exists" ]; then
                    if ! qm status "${effective_template_id}" >/dev/null 2>&1; then
                        error "Expected template ID (${effective_template_id}) to exist, but it does not"
                    elif ! qm config "${effective_template_id}" | grep -q '^template: 1'; then
                        error "ID (${effective_template_id}) exists but is not marked as a template"
                    fi
                fi
            fi
        fi
    fi
fi

if [ -n "${VM_IP}" ]; then
    if ! is_positive_int "${VM_IP}"; then
        error "--vm-ip (${VM_IP}) must be a positive integer"
    elif [ "${VM_IP}" -lt 2 ] || [ "${VM_IP}" -gt 254 ]; then
        error "--vm-ip (${VM_IP}) should usually be in range 2-254"
    elif [ -n "${VM_NETWORK:-}" ]; then
        target_ip="${VM_NETWORK}.${VM_IP}"
        escaped_ip="${target_ip//./\\.}"
        matching_ids="$(qm list | awk 'NR>1 { print $1 }' | while read -r id; do
            [ -z "${id}" ] && continue
            if qm config "${id}" 2>/dev/null | grep -Eq "^ipconfig0:.*ip=${escaped_ip}/"; then
                printf "%s " "${id}"
            fi
        done)"

        if [ -n "${matching_ids}" ]; then
            warn "IP (${target_ip}) already appears in ipconfig0 on VM IDs: ${matching_ids}"
        fi
    fi
fi

if [ "${ERROR_COUNT}" -gt 0 ]; then
    echo "Validation failed: ${ERROR_COUNT} error(s), ${WARN_COUNT} warning(s)"
    exit 1
fi

if [ "${WARN_COUNT}" -gt 0 ]; then
    echo "Validation passed with ${WARN_COUNT} warning(s)"
else
    echo "Validation passed"
fi

exit 0