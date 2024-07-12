#!/bin/bash

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
        wget -O $IMG_NAME "${IMG_URL}"
    fi
}

function make_auth_keys() {
    if [ ! -e ~/keys ]; then
        exit "No keys found"
    fi

    if [ -e ~/auth.keys ]; then
        rm ~/auth.keys
    fi

    for filename in ~/keys/*.pub; do
        cat filename > ~/auth.keys
    done

    cat auth.keys
}

function create_template() {
    VM_ID=$1
    VM_NAME=$2
    VM_IMAGE=$3

    # VM PARAMS
    OS_TYPE=l26
    VM_MEM=1024
    VM_CORES=2

    #Print all of the configuration
    echo "Creating template ${VM_NAME} (ID: ${VM_ID}) using image ${VM_IMAGE}"

    #Create new VM 
    qm create $1 --name $2 --ostype l26 
    #Set networking to default bridge
    qm set $1 --net0 virtio,bridge=vmbr0
    #Set display to serial
    qm set $1 --serial0 socket --vga serial0
    #Set memory, cpu, type defaults
    #If you are in a cluster, you might need to change cpu type
    qm set $1 --memory 1024 --cores 2 --cpu host
    #Set boot device to new file
    qm set $1 --scsi0 ${storage}:0,import-from="$(pwd)/$3",discard=on
    #Set scsi hardware as default boot disk using virtio scsi single
    qm set $1 --boot order=scsi0 --scsihw virtio-scsi-single
    #Enable Qemu guest agent in case the guest has it available
    qm set $1 --agent enabled=1,fstrim_cloned_disks=1
    #Add cloud-init device
    qm set $1 --ide2 ${storage}:cloudinit
    #Set CI ip config
    #IP6 = auto means SLAAC (a reliable default with no bad effects on non-IPv6 networks)
    #IP = DHCP means what it says, so leave that out entirely on non-IPv4 networks to avoid DHCP delays
    qm set $1 --ipconfig0 "ip6=auto,ip=dhcp"
    #Import the ssh keyfile
    qm set $1 --sshkeys ${ssh_keyfile}
    #If you want to do password-based auth instaed
    #Then use this option and comment out the line above
    #qm set $1 --cipassword password
    #Add the user
    qm set $1 --ciuser ${username}
    #Resize the disk to 8G, a reasonable minimum. You can expand it more later.
    #If the disk is already bigger than 8G, this will fail, and that is okay.
    qm disk resize $1 scsi0 8G
    #Make it a template
    qm template $1
}

ME=`whoami`

if [ "$ME" ne "root" ]; then 
    echo "You are not root, please sudo or become root"
    exit 1
fi

echo "Making the keys file"
make_auth_keys

echo "Downloading Fedora 40"
download_image "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2" "Fedora-40.qcow2"

echo "Downloading Ubuntu 24.04 LTS (Noble)"
download_image "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img" "Ubuntu-LTS-Server.img"
