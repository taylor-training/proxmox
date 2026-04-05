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
Usage: prod-k3s.sh [--dry-run|-n] [--confirm|-y]

Options:
  -n, --dry-run    Print matching prod VMIDs and exit without destroying
  -y, --confirm    Skip interactive confirmation and proceed
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

# Discover and remove existing prod VMs (by tag 'prod')
mapfile -t PROD_VMIDS < <(find_vmids_by_tag prod)
if [ "${#PROD_VMIDS[@]}" -gt 0 ]; then
	echo "Found prod VMIDs to remove: ${PROD_VMIDS[*]}"
	if [ "$DRY_RUN" = true ]; then
		echo "Dry-run: not destroying. Use script without --dry-run to perform destruction."
		exit 0
	fi
	if [ "$CONFIRM" != true ]; then
		printf "About to destroy %d VMs: %s\n" "${#PROD_VMIDS[@]}" "${PROD_VMIDS[*]}"
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
	shutdown_and_destroy "${PROD_VMIDS[@]}"
	sleep 5
else
	echo "No existing prod VMs found to remove"
fi

# K3s server and nodes for prod environment
./systems/ubuntu-server.sh k3s-prod-server1 17 "k3s,prod,server,kubernetes" --cpu 8 --balloon-min 2048 --memory 8192 --disk 200G
./systems/ubuntu-server.sh k3s-prod-server2 18 "k3s,prod,server,kubernetes" --cpu 8 --balloon-min 2048 --memory 8192 --disk 200G
./systems/ubuntu-server.sh k3s-prod-server3 19 "k3s,prod,server,kubernetes" --cpu 8 --balloon-min 2048 --memory 8192 --disk 200G
./systems/ubuntu-server.sh k3s-prod-node1 23 "k3s,prod,node,kubernetes" --cpu 8 --balloon-min 2048 --memory 8192 --disk 300G
./systems/ubuntu-server.sh k3s-prod-node2 24 "k3s,prod,node,kubernetes" --cpu 8 --balloon-min 2048 --memory 8192 --disk 300G
./systems/ubuntu-server.sh k3s-prod-node3 25 "k3s,prod,node,kubernetes" --cpu 8 --balloon-min 2048 --memory 8192 --disk 300G
./systems/ubuntu-server.sh k3s-prod-node4 26 "k3s,prod,node,kubernetes" --cpu 8 --balloon-min 2048 --memory 8192 --disk 300G
./systems/ubuntu-server.sh k3s-prod-node5 27 "k3s,prod,node,kubernetes" --cpu 8 --balloon-min 2048 --memory 8192 --disk 300G

# Postgresql server for prod environment
./systems/ubuntu-server.sh postgresql-prod 15 "prod,postgresql,psql" --cpu 8 --balloon-min 2048 --memory 8192 --disk 300G