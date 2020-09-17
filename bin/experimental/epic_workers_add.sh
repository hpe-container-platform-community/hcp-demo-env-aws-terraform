#!/bin/bash

HOST_IPS=( "$@" )

set -e # abort on error
set -u # abort on undefined variable

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

pip3 install --quiet --upgrade --user hpecp

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
echo "Platform ID: $(hpecp license platform-id)"

echo "Deleting and creating lock"
hpecp lock delete-all
hpecp lock create "Install EPIC Workers"

echo "Adding workers"
WRKR_IDS=()
for WRKR in ${HOST_IPS[@]}; do
    echo "   worker $WRKR"
    CMD="hpecp epicworker create-with-ssh-key --ip ${WRKR} --ssh-key-file ./generated/controller.prv_key"
    WRKR_ID="$($CMD)"
    echo "       id $WRKR_ID"
    WRKR_IDS+=($WRKR_ID)
done

echo "Waiting for workers to have state 'ready'"
for WRKR in ${WRKR_IDS[@]}; do
    echo "   worker $WRKR"
    hpecp epicworker wait-for-state ${WRKR} --states [ready] --timeout-secs 1800
done

echo "Setting worker storage"
for WRKR in ${WRKR_IDS[@]}; do
    echo "   worker $WRKR"
    hpecp epicworker set-storage --id ${WRKR} --persistent-disks=/dev/nvme1n1 --ephemeral-disks=/dev/nvme2n1
done

echo "Waiting for workers to have state 'installed'"
for WRKR in ${WRKR_IDS[@]}; do
    echo "   worker $WRKR"
    hpecp epicworker wait-for-state ${WRKR} --states [installed] --timeout-secs 1800
done

echo "Removing locks"
hpecp gateway list
hpecp lock delete-all --timeout-secs 1800
