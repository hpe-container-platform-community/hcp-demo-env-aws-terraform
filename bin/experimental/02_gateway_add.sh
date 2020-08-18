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

echo "Configuring the Gateway"
GATEWAY_ID=$(hpecp gateway create-with-ssh-key $GATW_PRV_IP $GATW_PRV_DNS --ssh-key-file ./generated/controller.prv_key)

echo "Waiting for gateway to have state 'installed'"
hpecp gateway wait-for-state ${GATEWAY_ID} --states "['installed']" --timeout-secs 1200

if [[ -f generated/cert.pem ]] && [[ -f generated/key.pem ]]; then
   echo "Setting up Gateway SSL certificate and key"
   CERTIFICATE=$(cat generated/cert.pem | perl -e 'while(<>) { $_ =~ s/[\r\n]/\\n/g; print "$_" }')
   KEY=$(cat generated/key.pem | perl -e 'while(<>) { $_ =~ s/[\r\n]/\\n/g; print "$_" }')
   JSON="{\"gateway_ssl_cert_info\": {\"cert_file\": {\"content\": \"${CERTIFICATE}\", \"file_name\": \"cert.pem\"}, \"key_file\": {\"content\": \"${KEY}\", \"file_name\": \"key.pem\"}}}"
   hpecp httpclient put /api/v1/install/?install_reconfig --json-file <(echo $JSON)
fi

echo "Removing locks"
hpecp gateway list
hpecp lock delete-all --timeout-secs 1200

