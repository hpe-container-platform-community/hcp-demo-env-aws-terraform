#!/bin/bash

HIDE_WARNINGS=${HIDE_WARNINGS:-0}

if [[ $# != 2 ]];
then
  echo Usage: $0 USERNAME PASSWORD
  exit 1
fi

USERNAME=$1
PASSWORD=$2

source "./scripts/variables.sh"

ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1


  sudo useradd -m -s /bin/bash $USERNAME

  # allow access to docker daemon
  sudo usermod -G docker $USERNAME
  
  # super-user privileges
  sudo usermod -G sudo $USERNAME
  
  echo $USERNAME:$PASSWORD | sudo chpasswd

EOF1