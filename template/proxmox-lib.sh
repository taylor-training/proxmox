#!/bin/bash

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "You are not root, please sudo or become root"
        exit 1
    fi
}

# Resolve project root (parent of this template/ directory) and
# default image directory under the install tree. This makes the
# default images path ${PROJECT_DIR}/images instead of $HOME/images
# when the scripts are run from an installed location (for example
# /opt/management/proxmox).
SCRIPT_DIR_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "${SCRIPT_DIR_LIB}/.." && pwd)}"
IMAGE_DIR="${IMAGE_DIR:-${PROJECT_DIR}/images}"

download_image() {
    local img_url="$1"
    local img_name="$2"
    local image_dir="${IMAGE_DIR:-${PROJECT_DIR}/images}"
    local image_path="${image_dir}/${img_name}"

    mkdir -p "${image_dir}"

    if [ -s "${image_path}" ]; then
        echo "${img_name} already exists, skipping download"
        return 0
    fi

    echo "Downloading ${img_name} from ${img_url}"
    wget -O "${image_path}" "${img_url}"
    echo "Downloading ${img_url} complete"
}

make_auth_keys() {
    local keys_dir="$HOME/keys"
    local output_file="$HOME/${SSHKEYS_FILE}"
    local key_count=0

    if [ -z "${SSHKEYS_FILE:-}" ]; then
        echo "SSHKEYS_FILE is not set in setup.conf"
        return 1
    fi

    if [ ! -d "${keys_dir}" ]; then
        echo "No keys - please put some RSA keys in ${keys_dir}"
        return 1
    fi

    : > "${output_file}"

    for filename in "${keys_dir}"/*.pub; do
        if [ ! -f "${filename}" ]; then
            continue
        fi

        echo "Adding key ${filename}"
        cat "${filename}" >> "${output_file}"
        key_count=$((key_count + 1))
    done

    if [ "${key_count}" -eq 0 ]; then
        echo "No .pub files found in ${keys_dir}"
        return 1
    fi

    echo "Creating auth keys completed"
    return 0
}

is_valid_cloud_init_profile_name() {
    local profile_name="$1"

    if [[ "${profile_name}" =~ ^[A-Za-z0-9._-]+$ ]]; then
        return 0
    fi

    return 1
}

combine_cloud_init_user_data_fragments() {
    local output_file="$1"
    shift
    local fragments=("$@")

    {
        echo "#cloud-config"
        for fragment in "${fragments[@]}"; do
            echo
            echo "# fragment: ${fragment}"
            awk '/^[[:space:]]*#cloud-config[[:space:]]*$/ { next } { print }' "${fragment}"
        done
    } > "${output_file}"
}

count_ssh_keys_file_entries() {
    local ssh_keys_file="$1"
    local first_content_line=""

    first_content_line="$(awk 'NF && $1 !~ /^#/ { print; exit }' "${ssh_keys_file}")"

    if [[ "${first_content_line}" == ssh_authorized_keys:* ]]; then
        awk '/^[[:space:]]*-/ { count++ } END { print count+0 }' "${ssh_keys_file}"
    else
        awk 'NF && $1 !~ /^#/ { count++ } END { print count+0 }' "${ssh_keys_file}"
    fi
}

apply_cloud_init_profile() {
    local vm_id="$1"
    local profile_name="$2"
    local config_root="${CLOUD_INIT_CONFIG_ROOT:-$HOME/configs}"
    local common_dir="${config_root}/common"
    local systems_dir="${config_root}/systems"
    local snippet_storage="${CLOUD_INIT_SNIPPET_STORAGE:-local}"
    local snippet_dir="${CLOUD_INIT_SNIPPET_DIR:-/var/lib/vz/snippets}"
    local common_user_file="${common_dir}/user-data.yaml"
    local common_ssh_file="${common_dir}/ssh-authorized-keys.yaml"
    local common_network_file="${common_dir}/network-data.yaml"
    local common_meta_file="${common_dir}/meta-data.yaml"
    local system_user_file="${systems_dir}/${profile_name}.user-data.yaml"
    local system_network_file="${systems_dir}/${profile_name}.network-data.yaml"
    local system_meta_file="${systems_dir}/${profile_name}.meta-data.yaml"
    local base_user_file=""
    local user_fragments=()
    local custom_user_count=0
    local user_snippet=""
    local network_source=""
    local meta_source=""
    local network_snippet=""
    local meta_snippet=""
    local cicustom_values=()
    local cicustom
    local snippet_content=""
    local include_network_data="${CLOUD_INIT_INCLUDE_NETWORK_DATA:-false}"

    if ! is_valid_cloud_init_profile_name "${profile_name}"; then
        echo "Cloud-init profile name (${profile_name}) must only contain letters, numbers, dots, underscores, and dashes"
        return 1
    fi

    if ! pvesm status -storage "${snippet_storage}" >/dev/null 2>&1; then
        echo "Cloud-init snippet storage (${snippet_storage}) does not exist or is unavailable"
        return 1
    fi

    snippet_content="$(pvesm config "${snippet_storage}" 2>/dev/null | awk '/^content / { print $2 }')"
    if [ -n "${snippet_content}" ] && ! printf ',%s,' "${snippet_content}" | grep -q ',snippets,'; then
        echo "Cloud-init snippet storage (${snippet_storage}) does not advertise snippets content"
        return 1
    fi

    mkdir -p "${snippet_dir}"

    base_user_file="${snippet_dir}/${profile_name}-${vm_id}-base-user.yaml"
    if ! qm cloudinit dump "${vm_id}" user > "${base_user_file}" 2>/dev/null; then
        echo "Unable to read generated cloud-init user-data for VM ${vm_id}"
        return 1
    fi
    user_fragments+=("${base_user_file}")

    if [ -f "${common_user_file}" ]; then
        user_fragments+=("${common_user_file}")
        custom_user_count=$((custom_user_count + 1))
    fi
    if [ -f "${common_ssh_file}" ]; then
        user_fragments+=("${common_ssh_file}")
        custom_user_count=$((custom_user_count + 1))
    fi
    if [ -f "${system_user_file}" ]; then
        user_fragments+=("${system_user_file}")
        custom_user_count=$((custom_user_count + 1))
    fi

    case "${include_network_data,,}" in
        1|true|yes|on)
            if [ -f "${system_network_file}" ]; then
                network_source="${system_network_file}"
            elif [ -f "${common_network_file}" ]; then
                network_source="${common_network_file}"
            fi
            ;;
        *)
            if [ -f "${system_network_file}" ] || [ -f "${common_network_file}" ]; then
                echo "Skipping cloud-init network-data overrides (CLOUD_INIT_INCLUDE_NETWORK_DATA=${include_network_data}) to preserve Proxmox ipconfig0"
            fi
            ;;
    esac

    if [ -n "${network_source}" ]; then
        network_snippet="${snippet_dir}/${profile_name}-${vm_id}-network.yaml"
        cp "${network_source}" "${network_snippet}"
    fi

    if [ -f "${system_meta_file}" ]; then
        meta_source="${system_meta_file}"
    elif [ -f "${common_meta_file}" ]; then
        meta_source="${common_meta_file}"
    fi

    if [ "${custom_user_count}" -eq 0 ] && [ -z "${network_source}" ] && [ -z "${meta_source}" ]; then
        echo "No cloud-init overrides found for profile ${profile_name}"
        echo "Expected one or more of:"
        echo "  ${common_user_file}"
        echo "  ${common_ssh_file}"
        echo "  ${system_user_file}"
        echo "  ${common_network_file}"
        echo "  ${system_network_file}"
        echo "  ${common_meta_file}"
        echo "  ${system_meta_file}"
        return 1
    fi

    user_snippet="${snippet_dir}/${profile_name}-${vm_id}-user.yaml"
    combine_cloud_init_user_data_fragments "${user_snippet}" "${user_fragments[@]}"

    if [ -n "${meta_source}" ]; then
        meta_snippet="${snippet_dir}/${profile_name}-${vm_id}-meta.yaml"
        cp "${meta_source}" "${meta_snippet}"
    fi

    cicustom_values+=("user=${snippet_storage}:snippets/$(basename "${user_snippet}")")

    if [ -n "${network_snippet}" ]; then
        cicustom_values+=("network=${snippet_storage}:snippets/$(basename "${network_snippet}")")
    fi

    if [ -n "${meta_snippet}" ]; then
        cicustom_values+=("meta=${snippet_storage}:snippets/$(basename "${meta_snippet}")")
    fi

    cicustom="$(IFS=,; echo "${cicustom_values[*]}")"
    echo "Applying cloud-init profile ${profile_name} to VM ${vm_id} (${cicustom})"
    qm set "${vm_id}" --cicustom "${cicustom}"
}

clone_template() {
    local tmpl_id="$1"
    local vm_id="$2"
    local vm_name="$3"
    local vm_ip="$4"
    local vm_tags="$5"
    local cloud_init_profile="$6"
    local vm_cores_override="$7"
    local vm_memory_override="$8"
    local vm_disk_size_override="$9"
    local disk_size="${vm_disk_size_override:-${VM_SPACE}}"
    local ip_config="ip6=auto,ip=dhcp"
    local hardware_args=()
    local ssh_keys_file_override="${SSH_AUTH_KEYS_FILE:-}"
    local ssh_keys_file=""
    local ssh_keys_count=0
    local rendered_user_data=""
    local rendered_ssh_keys_count=0

    if [ -n "${vm_ip}" ]; then
        ip_config="ip6=auto,ip=${VM_NETWORK}.${vm_ip}/24,gw=${VM_NETWORK}.1"
    fi

    echo "Cloning ${tmpl_id} to ${vm_name} (ID: ${vm_id}) on ${VM_DEVICE}"
    qm clone "${tmpl_id}" "${vm_id}" --name "${vm_name}" --storage "${VM_DEVICE}" --full 1

    if [ -n "${vm_tags}" ]; then
        qm set "${vm_id}" --tags "${vm_tags}"
    fi

    if [ -n "${vm_cores_override}" ]; then
        hardware_args+=(--cores "${vm_cores_override}")
    fi

    # Handle memory and ballooning. vm_memory_override is MB when set.
    local vm_balloon_min_override="${10:-}"
    local mem
    if [ -n "${vm_memory_override}" ]; then
        mem="${vm_memory_override}"
    else
        mem="${VM_MEMORY}"
    fi

    if [ "${vm_balloon_min_override}" = "0" ]; then
        # fixed memory
        hardware_args+=(--memory "${mem}" --balloon 0)
    else
        # ballooning enabled; determine minimum (default half)
        if [ -n "${vm_balloon_min_override}" ]; then
            balloon_min="${vm_balloon_min_override}"
        else
            # integer division
            balloon_min=$((mem / 2))
        fi
        hardware_args+=(--memory "${mem}" --balloon "${balloon_min}")
    fi

    if [ "${#hardware_args[@]}" -gt 0 ]; then
        qm set "${vm_id}" "${hardware_args[@]}"
    fi

    if [ -n "${ssh_keys_file_override}" ] && [ -f "${ssh_keys_file_override}" ]; then
        ssh_keys_file="${ssh_keys_file_override}"
    elif [ -n "${SSHKEYS_FILE:-}" ] && [ -f "$HOME/${SSHKEYS_FILE}" ]; then
        ssh_keys_file="$HOME/${SSHKEYS_FILE}"
    fi

    if [ -n "${ssh_keys_file}" ]; then
        ssh_keys_count="$(count_ssh_keys_file_entries "${ssh_keys_file}")"
        echo "Applying ${ssh_keys_count} SSH key(s) from ${ssh_keys_file}"
        if [ "${ssh_keys_count}" -eq 0 ]; then
            echo "Warning: ${ssh_keys_file} contains zero SSH keys"
        fi
        qm set "${vm_id}" --sshkeys "${ssh_keys_file}"
    else
        echo "Warning: no SSH keys file found for VM ${vm_id}; SSH key-based login may be unavailable"
    fi

    qm set "${vm_id}" --cipassword "$(openssl passwd -6 "${VM_PASS}")"
    qm set "${vm_id}" --ipconfig0 "${ip_config}"
    qm disk resize "${vm_id}" virtio0 "${disk_size}"

    if [ -n "${cloud_init_profile}" ]; then
        apply_cloud_init_profile "${vm_id}" "${cloud_init_profile}"
    fi

    if rendered_user_data="$(qm cloudinit dump "${vm_id}" user 2>/dev/null)"; then
        rendered_ssh_keys_count="$(printf '%s\n' "${rendered_user_data}" | awk '/^[[:space:]]*ssh_authorized_keys:[[:space:]]*$/ { in_list=1; next } in_list && /^[[:space:]]*-/ { count++ } END { print count+0 }')"
        echo "Cloud-init rendered SSH key count for VM ${vm_id}: ${rendered_ssh_keys_count}"
    else
        echo "Warning: unable to render cloud-init user-data for VM ${vm_id} to validate SSH key count"
    fi

    echo "Cloning ${tmpl_id} template complete"
}

create_template() {
    local vm_id="$1"
    local vm_name="$2"
    local vm_image="$3"
    local create_tmpl="$4"
    local tags="$5"
    local balloon_min_override="${6:-}"
    local os_type="l26"
    local ssh_keyfile="$HOME/${SSHKEYS_FILE}"
    local image_path="${vm_image}"
    local default_image_path="${IMAGE_DIR:-$HOME/images}/${vm_image}"
    local template_base_disk="${TEMPLATE_BASE_DISK:-10G}"
    local imported_volume=""

    if [ -f "${default_image_path}" ]; then
        image_path="${default_image_path}"
    fi

    if [ ! -f "${image_path}" ]; then
        echo "Unable to find image ${vm_image}. Checked ${image_path}"
        return 1
    fi

    echo "Creating template ${vm_name} (ID: ${vm_id}) using image ${image_path}"

    qm create "${vm_id}" --name "${vm_name}" --ostype "${os_type}" --agent 1 --bios ovmf --machine q35 --efidisk0 "${VM_DEVICE}:0,pre-enrolled-keys=0"
    qm set "${vm_id}" --net0 virtio,bridge=vmbr0
    qm set "${vm_id}" --serial0 socket --vga serial0
    # Apply memory and balloon settings. If balloon_min_override == 0 then fixed memory (balloon 0).
    local mem="${VM_MEMORY}"
    if [ "${balloon_min_override}" = "0" ]; then
        qm set "${vm_id}" --memory "${mem}" --cores "${VM_CORES}" --cpu host --balloon 0
    else
        if [ -n "${balloon_min_override}" ]; then
            balloon_min="${balloon_min_override}"
        else
            balloon_min=$((mem / 2))
        fi
        qm set "${vm_id}" --memory "${mem}" --cores "${VM_CORES}" --cpu host --balloon "${balloon_min}"
    fi
    qm importdisk "${vm_id}" "${image_path}" "${VM_DEVICE}"

    imported_volume="$(qm config "${vm_id}" | awk -F': ' '/^unused[0-9]+: / { print $2; exit }')"
    if [ -z "${imported_volume}" ]; then
        echo "Unable to detect imported disk volume for VM ${vm_id}"
        return 1
    fi

    qm set "${vm_id}" --scsihw virtio-scsi-pci --virtio0 "${imported_volume},discard=on"
    qm set "${vm_id}" --boot order=virtio0
    qm set "${vm_id}" --ide2 "${VM_DEVICE}:cloudinit"
    qm set "${vm_id}" --ipconfig0 "ip6=auto,ip=dhcp"

    if [ -f "${ssh_keyfile}" ]; then
        echo "Found key file ${ssh_keyfile}"
        qm set "${vm_id}" --sshkeys "${ssh_keyfile}"
    else
        echo "No combined keyfile found (${ssh_keyfile}), template will use password auth"
    fi

    qm set "${vm_id}" --ciuser "${VM_USER}"

    if [ -n "${tags}" ]; then
        qm set "${vm_id}" --tags "${tags},cloudinit"
    else
        qm set "${vm_id}" --tags "cloudinit"
    fi

    if [ "${create_tmpl}" = "true" ]; then
        qm set "${vm_id}" --description "Template for ${vm_name} using image ${vm_image}"
        qm set "${vm_id}" --name "${vm_name}-Template"
        qm disk resize "${vm_id}" virtio0 "${template_base_disk}" || true
        qm template "${vm_id}"
    else
        qm disk resize "${vm_id}" virtio0 "${VM_SPACE}"
    fi

    echo "Done"
}