#!/bin/bash

set -euo pipefail

usage() {
    echo "Usage: $0 [keys_dir] [output_file]"
    echo "Defaults: keys_dir=~/keys output_file=~/auth.keys"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

KEYS_DIR="${1:-$HOME/keys}"
OUTPUT_FILE="${2:-$HOME/auth.keys}"

if [ ! -d "${KEYS_DIR}" ]; then
    echo "Keys directory not found: ${KEYS_DIR}"
    exit 1
fi

shopt -s nullglob
pub_files=("${KEYS_DIR}"/*.pub)

if [ "${#pub_files[@]}" -eq 0 ]; then
    echo "No .pub files found in ${KEYS_DIR}"
    exit 1
fi

tmp_file="$(mktemp)"
trap 'rm -f "${tmp_file}"' EXIT

for file in "${pub_files[@]}"; do
    if [ ! -f "${file}" ]; then
        continue
    fi

    echo "Adding ${file}"
    cat "${file}" >> "${tmp_file}"
done

awk 'NF && !seen[$0]++' "${tmp_file}" > "${OUTPUT_FILE}"

echo "Wrote combined keys to ${OUTPUT_FILE}"
echo "Total unique keys: $(wc -l < "${OUTPUT_FILE}")"