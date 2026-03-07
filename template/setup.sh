#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_SETUP_SCRIPT="${SCRIPT_DIR}/../setup-template.sh"

if [ ! -f "${ROOT_SETUP_SCRIPT}" ]; then
    echo "Unable to find root setup script at ${ROOT_SETUP_SCRIPT}"
    exit 1
fi

exec "${ROOT_SETUP_SCRIPT}" "$@"