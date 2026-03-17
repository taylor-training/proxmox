#!/usr/bin/env bash
# Helper: shutdown and destroy VMs by VMID using `qm`
# Usage:
#   shutdown_and_destroy <vmid> [<vmid> ...]
# Controls:
#   Set SHUTDOWN_TIMEOUT to change graceful shutdown wait (seconds)

shutdown_and_destroy() {
    if ! command -v qm >/dev/null 2>&1; then
        echo "qm command not found; unable to shutdown/destroy VMs" >&2
        return 2
    fi

    local timeout=${SHUTDOWN_TIMEOUT:-60}
    local id

    for id in "$@"; do
        if [ -z "$id" ]; then
            continue
        fi

        echo "Shutting down VM $id (if running)"
        qm shutdown "$id" || true

        local waited=0
        while true; do
            state=$(qm status "$id" 2>/dev/null | awk '{print $2}') || state=""
            if [[ "$state" == "stopped" || "$state" == "shutdown" || -z "$state" ]]; then
                echo "VM $id stopped"
                break
            fi
            if [ "$waited" -ge "$timeout" ]; then
                echo "Timeout waiting for $id to shutdown; forcing stop"
                qm stop "$id" || true
                break
            fi
            sleep 3
            waited=$((waited + 3))
        done

        echo "Destroying VM $id and unreferenced disks"
        qm destroy "$id" --destroy-unreferenced-disks || true
    done
}

export -f shutdown_and_destroy 2>/dev/null || true
