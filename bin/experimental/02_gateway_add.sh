#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

echo "Deleting and creating lock"
hpecp lock delete-all
hpecp lock create "Install Gateway"

if [[ "${CREATE_EIP_GATEWAY}" == "True" ]];
then
   CONFIG_GATEWAY_DNS=$GATW_PUB_DNS
else
   CONFIG_GATEWAY_DNS=$GATW_PRV_DNS
fi

echo "Configuring the Gateway"
GATEWAY_ID=$(hpecp gateway create-with-ssh-key "$GATW_PRV_IP" "$CONFIG_GATEWAY_DNS" --ssh-key-file ./generated/controller.prv_key)

echo "Waiting for gateway to have state 'installed'"
hpecp gateway wait-for-state "${GATEWAY_ID}" --states "['installed']" --timeout-secs 1800

echo "Removing locks"
hpecp gateway list
hpecp lock delete-all --timeout-secs 1800

