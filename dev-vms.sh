#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# CLI flags
DRY_RUN=false
CONFIRM=false
while [ "$#" -gt 0 ]; do
	case "$1" in
		-n|--dry-run)
			DRY_RUN=true
			shift
			;;
		-y|--yes|--confirm)
			CONFIRM=true
			shift
			;;
		-h|--help)
			cat <<'USAGE'
Usage: stage-k3s.sh [--dry-run|-n]

Options:
  -n, --dry-run    Print matching stage VMIDs and exit without destroying
  -h, --help       Show this help
USAGE
			exit 0
			;;
		*)
			echo "Unknown argument: $1" >&2
			exit 2
			;;
	esac
done

# Load utility helpers
if [ -f "${SCRIPT_DIR}/utils/find-vmids-by-tag.sh" ]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/utils/find-vmids-by-tag.sh"
else
    echo "Helper ${SCRIPT_DIR}/utils/find-vmids-by-tag.sh not found" >&2
    exit 1
fi
if [ -f "${SCRIPT_DIR}/utils/shutdown-vms.sh" ]; then
	# shellcheck source=/dev/null
	source "${SCRIPT_DIR}/utils/shutdown-vms.sh"
else
	echo "Helper ${SCRIPT_DIR}/utils/shutdown-vms.sh not found" >&2
	exit 1
fi

# Discover and remove existing dev VMs (by tag 'dev')
mapfile -t DEV_VMIDS < <(find_vmids_by_tag dev)
if [ "${#DEV_VMIDS[@]}" -gt 0 ]; then
	echo "Found dev VMIDs to remove: ${DEV_VMIDS[*]}"
	if [ "$DRY_RUN" = true ]; then
		echo "Dry-run: not destroying. Use script without --dry-run to perform destruction."
		exit 0
	fi
	if [ "$CONFIRM" != true ]; then
		printf "About to destroy %d VMs: %s\n" "${#DEV_VMIDS[@]}" "${DEV_VMIDS[*]}"
		read -r -p "Proceed? (y/N): " answer
		case "${answer,,}" in
			y|yes)
				;;
			*)
				echo "Aborting per user response"
				exit 0
				;;
		esac
	fi
	shutdown_and_destroy "${DEV_VMIDS[@]}"
	sleep 5
else
	echo "No existing dev VMs found to remove"
fi

./systems/ubuntu-server.sh k3s-dev-server 14 "k3s,dev,server,kubernetes" --cpu 8 --balloon-min 2048 --memory 8192 --disk 300G

# Postgresql server for dev environment
./systems/ubuntu-server.sh postgresql-dev 16 "dev,postgresql,psql" --cpu 8 --balloon-min 2048 --memory 8192 --disk 300G