#!/bin/bash

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

echo "Deleting and creating lock"
hpecp lock delete-all
hpecp lock create "Install Gateway"

set -x

#EXISTING_GATEWAY_IDS=$(hpecp gateway list --columns "['id']" --output text)
#for GW in ${EXISTING_GATEWAY_IDS}; do
#   hpecp gateway delete ${GW}
#   hpecp gateway wait-for-state ${GW} --states "[]" --timeout-secs 1200
#done

echo "Configuring the Gateway"
GATEWAY_ID=$(hpecp gateway create-with-ssh-key $GATW_PRV_IP $GATW_PRV_DNS --ssh-key-file ./generated/controller.prv_key)

echo "Waiting for gateway to have state 'installed'"
hpecp gateway wait-for-state ${GATEWAY_ID} --states "['installed']" --timeout-secs 1200
hpecp gateway list
hpecp lock delete-all

