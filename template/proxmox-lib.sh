function download_image() {
    IMG_URL=$1
    IMG_NAME=$2

    cd ~
    pwd
    
    if [ ! -e ~/images ]; then
        mkdir images
    fi

    cd images

    if [ -e ~/images/$IMG_NAME ]; then
        echo $IMG_NAME already exists, skipping download
    else
        echo "Downloading $IMG_NAME from ${IMG_URL}"
        wget -O $IMG_NAME "${IMG_URL}"
    fi

    echo "Downloading ${IMG_URL} complete"
}

function make_auth_keys() {
    if [ ! -d ~/keys ]; then
        echo "No keys - please put some RSA keys in the ~/keys folder of your Proxmox host"
        return
    fi

    if [ -f ~/auth.keys ]; then
        echo "Removing existing combined auth keys file"
        rm ~/auth.keys
    fi

    for filename in ~/keys/*.pub; do
        echo "Adding key ${filename}"
        cat $filename >> ~/auth.keys
    done

    cat ~/auth.keys
    echo "Creating auth keys completed"
}

function clone_template() {
    TMPL_ID=$1
    VM_ID=$2
    VM_NAME=$3
    VM_IP=$4
    VM_PASS=$5

    storage="storage-1"
    VM_NETWORK="192.168.50" # only first 3 of 4

    echo "Cloning $TMPL_ID to $VM_NAME (ID: ${VM_ID}) on ${storage}"

    qm clone $TMPL_ID $VM_ID --name $VM_NAME --storage ${storage} --full 1
    qm set $VM_ID --cipassword $(openssl passwd -6 $VM_PASS)
    qm set $VM_ID --ipconfig0 "ip6=auto,ip=${VM_NETWORK}.${VM_IP}/24,gw=${VM_NETWORK}.1"
    qm disk resize $VM_ID virtio0 40G

    echo "Cloning ${TMPL_ID} template complete"
}

function create_template() {
    VM_ID=$1
    VM_NAME=$2
    VM_IMAGE=$3
    CREATE_TMPL=$4
    TAGS=$5

    # User settings
    storage="storage-1"
    username="jason"

    # VM PARAMS
    OS_TYPE=l26
    VM_MEM=1024
    VM_CORES=1

    ssh_keyfile=~/auth.keys

    #Print all of the configuration
    echo "Creating template ${VM_NAME} (ID: ${VM_ID}) using image ${VM_IMAGE}"

    #Create new VM 
    qm create $VM_ID --name "${VM_NAME}" --ostype $OS_TYPE --agent 1 --bios ovmf --machine q35 --efidisk0 ${storage}:0,pre-enrolled-keys=0
    #Set networking to default bridge
    qm set $VM_ID --net0 virtio,bridge=vmbr0
    #Set display to serial
    qm set $VM_ID --serial0 socket --vga serial0
    #Set memory, cpu, type defaults
    #If you are in a cluster, you might need to change cpu type
    qm set $VM_ID --memory $VM_MEM --cores $VM_CORES --cpu host --balloon 0 --numa
    #Set boot device to new file
    qm importdisk ${VM_ID} ${VM_IMAGE} ${storage}
    # qm set $VM_ID --scsi0 ${storage}:0,import-from="$(pwd)/$VM_IMAGE",discard=on
    qm set $VM_ID --scsihw virtio-scsi-pci --virtio0 ${storage}:vm-$VM_ID-disk-1,discard=on
    #Set scsi hardware as default boot disk using virtio scsi single
    qm set $VM_ID --boot order=virtio0
    #Add cloud-init device
    qm set $VM_ID --ide2 ${storage}:cloudinit
    #Set CI ip config
    #IP6 = auto means SLAAC (a reliable default with no bad effects on non-IPv6 networks)
    #IP = DHCP means what it says, so leave that out entirely on non-IPv4 networks to avoid DHCP delays
    qm set $VM_ID --ipconfig0 "ip6=auto,ip=dhcp"
    #Import the ssh keyfile

    if [ -f "${ssh_keyfile}" ]; then
        echo "Found key file ${ssh_keyfile}"
        qm set $VM_ID --sshkeys ${ssh_keyfile}
    else
        echo "Please set the password in the template and regenerate the cloud-init disk"
    fi

    #If you want to do password-based auth instaed
    #Then use this option and comment out the line above
    #qm set $1 --cipassword password
    #Add the user
    qm set $VM_ID --ciuser ${username}

    qm set $VM_ID --cicustom "vendor=local:snippets/setup.yaml"

    qm set $VM_ID --tags template,cloudinit

    #Resize the disk to 8G, a reasonable minimum. You can expand it more later.
    #If the disk is already bigger than 8G, this will fail, and that is okay.
    if $CREATE_TMPL; then
        qm set $VM_ID --description "Template for ${VM_NAME} using image ${VM_IMAGE}"
        qm set $VM_ID --name "${VM_NAME}-Template"
        qm disk resize $VM_ID virtio0 8G
    else
        qm disk resize $VM_ID virtio0 40G
    fi
    #Make it a template

    if $CREATE_TMPL; then
        qm template $VM_ID
    fi

    echo "Done"
}