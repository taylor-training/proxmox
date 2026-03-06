#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_OUTPUT_FILE="${SCRIPT_DIR}/configs/common/network-data.yaml"
DEFAULT_SETUP_CONF="${SCRIPT_DIR}/template/setup.conf"

usage() {
    cat << 'EOF'
Usage: network-config.sh [options]

Creates a cloud-init network-data snippet for configs/common.

Options:
  --interface-pattern <pattern>  Interface match pattern (default: ens18)
  --dhcp4 <true|false>           Enable DHCPv4 (default: true)
  --dhcp6 <true|false>           Enable DHCPv6 (default: true)
  --nameservers <list>           Space/comma separated DNS servers
  --search-domains <list>        Space/comma separated search domains
  --output <path>                Output file path (default: ./configs/common/network-data.yaml)
  --setup-conf <path>            Optional setup.conf source for defaults
  --non-interactive              Do not prompt; use provided/default values
  --force                        Overwrite output file without prompt
  -h, --help                     Show this help

Examples:
  ./network-config.sh
  ./network-config.sh --nameservers "192.168.50.10 1.1.1.1" --search-domains "homelab.local"
  ./network-config.sh --interface-pattern "en*" --non-interactive --force
EOF
}

is_bool() {
    case "${1,,}" in
        true|false)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

normalize_list() {
    printf '%s' "$1" | tr ',' ' ' | xargs
}

prompt_value() {
    local prompt_text="$1"
    local default_value="$2"
    local input_value

    if [ -n "${default_value}" ]; then
        read -r -p "${prompt_text} [${default_value}]: " input_value
        printf '%s' "${input_value:-${default_value}}"
    else
        read -r -p "${prompt_text}: " input_value
        printf '%s' "${input_value}"
    fi
}

INTERFACE_PATTERN="ens18"
DHCP4="true"
DHCP6="true"
NAMESERVERS=""
SEARCH_DOMAINS=""
OUTPUT_FILE="${DEFAULT_OUTPUT_FILE}"
SETUP_CONF="${DEFAULT_SETUP_CONF}"
NON_INTERACTIVE="false"
FORCE_OVERWRITE="false"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --interface-pattern)
            shift
            INTERFACE_PATTERN="${1:-}"
            ;;
        --dhcp4)
            shift
            DHCP4="${1:-}"
            ;;
        --dhcp6)
            shift
            DHCP6="${1:-}"
            ;;
        --nameservers)
            shift
            NAMESERVERS="${1:-}"
            ;;
        --search-domains)
            shift
            SEARCH_DOMAINS="${1:-}"
            ;;
        --output)
            shift
            OUTPUT_FILE="${1:-}"
            ;;
        --setup-conf)
            shift
            SETUP_CONF="${1:-}"
            ;;
        --non-interactive)
            NON_INTERACTIVE="true"
            ;;
        --force)
            FORCE_OVERWRITE="true"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

if [ -f "${SETUP_CONF}" ]; then
    # shellcheck disable=SC1090
    source "${SETUP_CONF}"

    if [ -z "${NAMESERVERS}" ] && [ -n "${NAME_SERVERS:-}" ]; then
        NAMESERVERS="${NAME_SERVERS}"
    fi

    if [ -z "${SEARCH_DOMAINS}" ] && [ -n "${SEARCH_DOMAIN:-}" ]; then
        SEARCH_DOMAINS="${SEARCH_DOMAIN}"
    fi
fi

if [ "${NON_INTERACTIVE}" != "true" ]; then
    INTERFACE_PATTERN="$(prompt_value "Interface pattern" "${INTERFACE_PATTERN}")"
    DHCP4="$(prompt_value "Enable DHCPv4 (true/false)" "${DHCP4}")"
    DHCP6="$(prompt_value "Enable DHCPv6 (true/false)" "${DHCP6}")"
    NAMESERVERS="$(prompt_value "Name servers (space/comma separated, optional)" "${NAMESERVERS}")"
    SEARCH_DOMAINS="$(prompt_value "Search domains (space/comma separated, optional)" "${SEARCH_DOMAINS}")"
    OUTPUT_FILE="$(prompt_value "Output file" "${OUTPUT_FILE}")"
fi

if [ -z "${INTERFACE_PATTERN}" ]; then
    echo "Interface pattern cannot be empty"
    exit 1
fi

if ! is_bool "${DHCP4}"; then
    echo "--dhcp4 must be true or false"
    exit 1
fi

if ! is_bool "${DHCP6}"; then
    echo "--dhcp6 must be true or false"
    exit 1
fi

NAMESERVERS="$(normalize_list "${NAMESERVERS}")"
SEARCH_DOMAINS="$(normalize_list "${SEARCH_DOMAINS}")"

if [ -f "${OUTPUT_FILE}" ] && [ "${FORCE_OVERWRITE}" != "true" ]; then
    if [ "${NON_INTERACTIVE}" = "true" ]; then
        echo "Output file exists and --force was not specified: ${OUTPUT_FILE}"
        exit 1
    fi

    overwrite_answer="$(prompt_value "Output exists. Overwrite? (yes/no)" "no")"
    case "${overwrite_answer,,}" in
        y|yes)
            ;;
        *)
            echo "Aborted"
            exit 0
            ;;
    esac
fi

mkdir -p "$(dirname "${OUTPUT_FILE}")"

{
    echo "version: 2"
    echo "ethernets:"
    echo "  default:"
    echo "    match:"
    echo "      name: \"${INTERFACE_PATTERN}\""
    echo "    dhcp4: ${DHCP4}"
    echo "    dhcp6: ${DHCP6}"

    if [ -n "${NAMESERVERS}" ] || [ -n "${SEARCH_DOMAINS}" ]; then
        echo "    nameservers:"

        if [ -n "${NAMESERVERS}" ]; then
            echo "      addresses:"
            for ns in ${NAMESERVERS}; do
                echo "        - ${ns}"
            done
        fi

        if [ -n "${SEARCH_DOMAINS}" ]; then
            echo "      search:"
            for domain in ${SEARCH_DOMAINS}; do
                echo "        - ${domain}"
            done
        fi
    fi
} > "${OUTPUT_FILE}"

echo "Wrote cloud-init network snippet: ${OUTPUT_FILE}"
echo "Note: Using network-data via --cloud-init profile overrides Proxmox-generated network config (including ipconfig0)."
