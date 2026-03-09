#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATALOG_FILE="${SCRIPT_DIR}/distro-catalog.sh"

if [ ! -f "${CATALOG_FILE}" ]; then
    echo "Unable to find distro catalog at ${CATALOG_FILE}"
    exit 1
fi

source "${CATALOG_FILE}"

usage() {
    echo "Usage: $0 <distro> [image_path] [--gpg] [--no-checksum]"
    echo "Defaults: checksum verification enabled, GPG verification disabled"
    echo "Supported distros: $(list_supported_distros)"
}

download_file() {
    local url="$1"
    local output="$2"

    if command -v wget >/dev/null 2>&1; then
        wget -q -O "${output}" "${url}"
    elif command -v curl >/dev/null 2>&1; then
        curl --silent --show-error --fail --location --output "${output}" "${url}"
    else
        echo "Either wget or curl is required"
        return 1
    fi
}

extract_expected_hash() {
    local checksum_file="$1"
    local image_name="$2"

    awk -v image_name="${image_name}" '
        {
            line=$0
            gsub(/\r/, "", line)

            split(line, parts, /[[:space:]]+/)
            if (parts[1] ~ /^[A-Fa-f0-9]+$/ && (length(parts[1]) == 64 || length(parts[1]) == 128) && parts[2] != "") {
                candidate=parts[2]
                sub(/^\*/, "", candidate)
                if (candidate == image_name) {
                    print parts[1]
                    exit
                }
            }

            eq_pos=index(line, " = ")
            if (eq_pos > 0) {
                hash=substr(line, eq_pos + 3)
                if (hash ~ /^[A-Fa-f0-9]+$/ && (length(hash) == 64 || length(hash) == 128)) {
                    left=substr(line, 1, eq_pos - 1)
                    lparen=index(left, "(")
                    rparen=index(left, ")")
                    if (lparen > 0 && rparen > lparen) {
                        candidate=substr(left, lparen + 1, rparen - lparen - 1)
                        if (candidate == image_name) {
                            print hash
                            exit
                        }
                    }
                }
            }
        }
    ' "${checksum_file}"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

DISTRO="$1"
shift

IMAGE_PATH=""
VERIFY_CHECKSUM=true
VERIFY_GPG=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --gpg)
            VERIFY_GPG=true
            ;;
        --no-checksum)
            VERIFY_CHECKSUM=false
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            if [ -z "${IMAGE_PATH}" ]; then
                IMAGE_PATH="$1"
            else
                echo "Unknown argument: $1"
                usage
                exit 1
            fi
            ;;
    esac
    shift
done

if ! get_distro_config "${DISTRO}" >/dev/null 2>&1; then
    echo "Unsupported distro key: ${DISTRO}"
    echo "Supported distros: $(list_supported_distros)"
    exit 1
fi

if [ -z "${IMAGE_PATH}" ]; then
    IMAGE_DIR="${IMAGE_DIR:-$HOME/images}"
    IMAGE_PATH="${IMAGE_DIR}/${DISTRO_IMAGE_NAME}"
fi

if [ ! -f "${IMAGE_PATH}" ]; then
    echo "Image file not found: ${IMAGE_PATH}"
    exit 1
fi

if [ "${VERIFY_CHECKSUM}" != "true" ] && [ "${VERIFY_GPG}" != "true" ]; then
    echo "No verification requested"
    exit 0
fi

if [ -z "${DISTRO_CHECKSUM_URL}" ]; then
    if [ "${VERIFY_CHECKSUM}" = "true" ] || [ "${VERIFY_GPG}" = "true" ]; then
        echo "No checksum metadata URL configured for ${DISTRO_KEY}"
    fi
    exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

CHECKSUM_FILE="${TMP_DIR}/checksums.txt"

echo "Downloading checksums for ${DISTRO_KEY}"
download_file "${DISTRO_CHECKSUM_URL}" "${CHECKSUM_FILE}"

if [ "${VERIFY_GPG}" = "true" ]; then
    if ! command -v gpg >/dev/null 2>&1; then
        echo "gpg is required for signature verification"
        exit 1
    fi

    GPG_ARGS=(--batch)
    if [ -n "${IMAGE_GPG_KEYRING:-}" ]; then
        GPG_ARGS+=(--no-default-keyring --keyring "${IMAGE_GPG_KEYRING}")
    fi

    GPG_VERIFIED=false

    echo "Running GPG verification for ${DISTRO_KEY}"
    if [ "${DISTRO_CHECKSUM_CLEARSIGNED}" = "true" ]; then
        gpg "${GPG_ARGS[@]}" --verify "${CHECKSUM_FILE}"
        GPG_VERIFIED=true
    elif [ -n "${DISTRO_CHECKSUM_SIG_URL}" ]; then
        CHECKSUM_SIG_FILE="${TMP_DIR}/checksums.sig"
        download_file "${DISTRO_CHECKSUM_SIG_URL}" "${CHECKSUM_SIG_FILE}"
        gpg "${GPG_ARGS[@]}" --verify "${CHECKSUM_SIG_FILE}" "${CHECKSUM_FILE}"
        GPG_VERIFIED=true
    else
        echo "No checksum signature URL configured for ${DISTRO_KEY}; skipping GPG verify"
    fi

    if [ "${GPG_VERIFIED}" = "true" ]; then
        echo "GPG verification passed"
    fi
fi

if [ "${VERIFY_CHECKSUM}" = "true" ]; then
    IMAGE_NAME="$(basename "${IMAGE_PATH}")"
    CHECKSUM_IMAGE_NAME="${DISTRO_SOURCE_IMAGE_NAME:-$(basename "${DISTRO_IMAGE_URL}")}"
    EXPECTED_HASH="$(extract_expected_hash "${CHECKSUM_FILE}" "${CHECKSUM_IMAGE_NAME}")"

    if [ -z "${EXPECTED_HASH}" ]; then
        echo "Unable to find checksum entry for ${CHECKSUM_IMAGE_NAME} in ${DISTRO_CHECKSUM_URL}"
        exit 1
    fi

    EXPECTED_HASH="${EXPECTED_HASH,,}"

    case "${#EXPECTED_HASH}" in
        64)
            ACTUAL_HASH="$(sha256sum "${IMAGE_PATH}" | awk '{print $1}')"
            HASH_ALGO="sha256"
            ;;
        128)
            ACTUAL_HASH="$(sha512sum "${IMAGE_PATH}" | awk '{print $1}')"
            HASH_ALGO="sha512"
            ;;
        *)
            echo "Unsupported checksum length (${#EXPECTED_HASH}) for ${IMAGE_NAME}"
            exit 1
            ;;
    esac

    ACTUAL_HASH="${ACTUAL_HASH,,}"

    if [ "${ACTUAL_HASH}" != "${EXPECTED_HASH}" ]; then
        echo "Checksum mismatch for ${IMAGE_NAME}"
        echo "Expected (${HASH_ALGO}): ${EXPECTED_HASH}"
        echo "Actual   (${HASH_ALGO}): ${ACTUAL_HASH}"
        exit 1
    fi

    echo "Checksum verification passed (${HASH_ALGO})"
fi

echo "Image integrity verification complete"