#!/bin/bash
source "./scripts/variables.sh"


command -v sshfs >/dev/null 2>&1  || sudo yum install fuse-sshfs

./bin/ssh_rdp_linux_server.sh "[[ -d /home/ubuntu/clientmount ]] || mkdir /home/ubuntu/clientmount"

echo "Mounting '/home/ubuntu/clientmount' to '${PWD}/rdpmount'"

sshfs -o StrictHostKeyChecking=no \
    -o IdentityFile="${PWD}/generated/controller.prv_key" \
    ubuntu@$RDP_PUB_IP:/home/ubuntu/clientmount \
    ${PWD}/rdpmount
 
echo "To unmount:"   
echo "fusermount -u ${PWD}/rdpmount"
