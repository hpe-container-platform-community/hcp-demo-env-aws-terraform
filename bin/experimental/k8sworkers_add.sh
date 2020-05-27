#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

../../scripts/check_prerequisites.sh
source ../../scripts/variables.sh

pip3 install --quiet --upgrade git+https://github.com/hpe-container-platform-community/hpecp-client@master

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="../../generated/hpecp.conf"

echo "Adding workers"
WRKR_IDS=()
for WRKR in ${WRKR_PRV_IPS[@]}; do
    echo "   worker $WRKR"
    WRKR_IDS+=($(hpecp k8sworker create-with-ssh-key --ip ${WRKR} --ssh-key-file ../../generated/controller.prv_key))
done

# TODO fix: k8sworker wait-for-state
sleep 1200

echo "Setting worker storage"
for WRKR in "${WRKR_IDS[@]}" 
do
    echo "   worker $WRKR"
    hpecp k8sworker set-storage --k8sworker_id ${WRKR} --persistent-disks=/dev/nvme2n1 --ephemeral-disks=/dev/nvme2n1
done

