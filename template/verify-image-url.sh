#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATALOG_FILE="${SCRIPT_DIR}/distro-catalog.sh"

if [ ! -f "${CATALOG_FILE}" ]; then
    echo "Unable to find distro catalog at ${CATALOG_FILE}"
    exit 1
fi

source "${CATALOG_FILE}"

usage() {
    echo "Usage: $0 [--all | <distro> ...]"
    echo "Checks catalog image URLs with wget --spider or curl --head"
    echo "Supported distros: $(list_supported_distros)"
}

HTTP_CHECK_TOOL=""
if command -v wget >/dev/null 2>&1; then
    HTTP_CHECK_TOOL="wget"
elif command -v curl >/dev/null 2>&1; then
    HTTP_CHECK_TOOL="curl"
else
    echo "Either wget or curl is required for URL checks"
    exit 1
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

declare -a distros
if [ "$#" -eq 0 ] || [ "${1:-}" = "--all" ]; then
    read -r -a distros <<< "$(list_supported_distros)"
else
    distros=("$@")
fi

timeout="${URL_CHECK_TIMEOUT:-20}"
tries="${URL_CHECK_TRIES:-2}"

ok_count=0
fail_count=0

for distro in "${distros[@]}"; do
    if ! get_distro_config "${distro}" >/dev/null 2>&1; then
        echo "[FAIL] ${distro}: unsupported distro key"
        fail_count=$((fail_count + 1))
        continue
    fi

    printf "Checking %-8s %s ... " "${DISTRO_KEY}" "${DISTRO_IMAGE_URL}"
    if [ "${HTTP_CHECK_TOOL}" = "wget" ]; then
        wget --spider --quiet --tries="${tries}" --timeout="${timeout}" "${DISTRO_IMAGE_URL}"
    else
        curl --head --silent --show-error --fail --location --max-time "${timeout}" "${DISTRO_IMAGE_URL}" >/dev/null
    fi

    if [ "$?" -eq 0 ]; then
        echo "OK"
        ok_count=$((ok_count + 1))
    else
        echo "FAILED"
        fail_count=$((fail_count + 1))
    fi
done

echo "URL checks complete: ${ok_count} passed, ${fail_count} failed"

if [ "${fail_count}" -gt 0 ]; then
    exit 1
fi

exit 0