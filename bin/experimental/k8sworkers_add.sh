#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

pip3 install --quiet --upgrade git+https://github.com/hpe-container-platform-community/hpecp-client@master

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
hpecp license platform-id

echo "Adding workers"
WRKR_IDS=()
for WRKR in ${WRKR_PRV_IPS[@]}; do
    echo "   worker $WRKR"
    CMD="hpecp k8sworker create-with-ssh-key --ip ${WRKR} --ssh-key-file ./generated/controller.prv_key"
    WRKR_ID="$($CMD)"
    echo "       id $WRKR_ID"
    WRKR_IDS+=($WRKR_ID)
done

echo "Waiting for workers to have state 'storage_pending'"
for WRKR in ${WRKR_IDS[@]}; do
    echo "   worker $WRKR"
    hpecp k8sworker wait-for-status ${WRKR} --status  "['storage_pending']"
done

echo "Setting worker storage"
for WRKR in ${WRKR_IDS[@]}; do
    echo "   worker $WRKR"
    hpecp k8sworker set-storage --k8sworker_id ${WRKR} --persistent-disks=/dev/nvme2n1 --ephemeral-disks=/dev/nvme2n1
done

