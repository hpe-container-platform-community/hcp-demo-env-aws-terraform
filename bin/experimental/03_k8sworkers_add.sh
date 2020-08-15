#!/bin/bash

NUM_HOSTS=$1

set -e # abort on error
set -u # abort on undefined variable

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

# if the user hasn't provided a desired number of hosts to use 
# for workers, use them all
if [[ -z $NUM_HOSTS ]]; then
    NUM_HOSTS=${WORKER_COUNT}
fi

if [[ $NUM_HOSTS -gt $WORKER_COUNT ]]; then
    echo "Aborting. ${NUM_HOSTS} hosts requested but only ${WORKER_COUNT} available."
    exit 1
fi


pip3 install --quiet --upgrade --user hpecp

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
echo "Platform ID: $(hpecp license platform-id)"

echo "Adding workers"
WRKR_IDS=()
for WRKR in ${WRKR_PRV_IPS[@]:0:$NUM_HOSTS}; do
    echo "   worker $WRKR"
    CMD="hpecp k8sworker create-with-ssh-key --ip ${WRKR} --ssh-key-file ./generated/controller.prv_key"
    WRKR_ID="$($CMD)"
    echo "       id $WRKR_ID"
    WRKR_IDS+=($WRKR_ID)
done

echo "Waiting for workers to have state 'storage_pending'"
for WRKR in ${WRKR_IDS[@]:0:$NUM_HOSTS}; do
    echo "   worker $WRKR"
    hpecp k8sworker wait-for-status ${WRKR} --status  "['storage_pending']" --timeout-secs 1200
done

echo "Setting worker storage"
for WRKR in ${WRKR_IDS[@]:0:$NUM_HOSTS}; do
    echo "   worker $WRKR"
    hpecp k8sworker set-storage --id ${WRKR} --persistent-disks=/dev/nvme1n1 --ephemeral-disks=/dev/nvme2n1
done

echo "Waiting for workers to have state 'ready'"
for WRKR in ${WRKR_IDS[@]:0:$NUM_HOSTS}; do
    echo "   worker $WRKR"
    hpecp k8sworker wait-for-status ${WRKR} --status  "['ready']" --timeout-secs 1200
done
