#!/usr/bin/env bash
# Helper: find VMIDs by tag or name substring using `qm`
# Usage:
#   find_vmids_by_tag <tag>
# Prints matching VMIDs (one per line). Safe to source.

find_vmids_by_tag() {
    local tag="$1"
    local ids=()

    if [ -z "${tag:-}" ]; then
        return 1
    fi

    # iterate qm list VMIDs (skip header)
    while read -r vmid _rest; do
        if [[ "${vmid}" == "VMID" || -z "${vmid}" ]]; then
            continue
        fi

        # read qm config for name/tags (quietly)
        cfg=$(qm config "${vmid}" 2>/dev/null || true)
        vmname=$(printf '%s' "${cfg}" | awk -F': ' '/^name:/ {print $2; exit}')
        vmtags=$(printf '%s' "${cfg}" | awk -F': ' '/^tags:/ {print $2; exit}')

        if [[ "${vmtags,,}" == *"${tag,,}"* ]] || [[ "${vmname,,}" == *"${tag,,}"* ]]; then
            ids+=("${vmid}")
        fi
    done < <(qm list)

    if [ "${#ids[@]}" -gt 0 ]; then
        printf '%s\n' "${ids[@]}"
        return 0
    fi

    return 1
}

export -f find_vmids_by_tag 2>/dev/null || true
