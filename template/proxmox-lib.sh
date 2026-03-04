#!/bin/bash

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "You are not root, please sudo or become root"
        exit 1
    fi
}

download_image() {
    local img_url="$1"
    local img_name="$2"
    local image_dir="${IMAGE_DIR:-$HOME/images}"
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

clone_template() {
    local tmpl_id="$1"
    local vm_id="$2"
    local vm_name="$3"
    local vm_ip="$4"
    local vm_tags="$5"
    local ip_config="ip6=auto,ip=dhcp"

    if [ -n "${vm_ip}" ]; then
        ip_config="ip6=auto,ip=${VM_NETWORK}.${vm_ip}/24,gw=${VM_NETWORK}.1"
    fi

    echo "Cloning ${tmpl_id} to ${vm_name} (ID: ${vm_id}) on ${VM_DEVICE}"
    qm clone "${tmpl_id}" "${vm_id}" --name "${vm_name}" --storage "${VM_DEVICE}" --full 1

    if [ -n "${vm_tags}" ]; then
        qm set "${vm_id}" --tags "${vm_tags}"
    fi

    qm set "${vm_id}" --cipassword "$(openssl passwd -6 "${VM_PASS}")"
    qm set "${vm_id}" --ipconfig0 "${ip_config}"
    qm disk resize "${vm_id}" virtio0 "${VM_SPACE}"

    echo "Cloning ${tmpl_id} template complete"
}

create_template() {
    local vm_id="$1"
    local vm_name="$2"
    local vm_image="$3"
    local create_tmpl="$4"
    local tags="$5"
    local os_type="l26"
    local ssh_keyfile="$HOME/${SSHKEYS_FILE}"
    local image_path="${vm_image}"
    local default_image_path="${IMAGE_DIR:-$HOME/images}/${vm_image}"

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
    qm set "${vm_id}" --memory "${VM_MEMORY}" --cores "${VM_CORES}" --cpu host --balloon 0
    qm importdisk "${vm_id}" "${image_path}" "${VM_DEVICE}"
    qm set "${vm_id}" --scsihw virtio-scsi-pci --virtio0 "${VM_DEVICE}:vm-${vm_id}-disk-1,discard=on"
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
        qm disk resize "${vm_id}" virtio0 8G || true
        qm template "${vm_id}"
    else
        qm disk resize "${vm_id}" virtio0 "${VM_SPACE}"
    fi

    echo "Done"
}