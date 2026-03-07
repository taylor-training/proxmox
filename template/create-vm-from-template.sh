#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEMS_VM_SCRIPT="${SCRIPT_DIR}/../systems/create-vm-from-template.sh"

if [ ! -f "${SYSTEMS_VM_SCRIPT}" ]; then
    echo "Unable to find systems VM script at ${SYSTEMS_VM_SCRIPT}"
    exit 1
fi

exec "${SYSTEMS_VM_SCRIPT}" "$@"