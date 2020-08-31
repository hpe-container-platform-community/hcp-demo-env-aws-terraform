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

echo "SSL info:"
hpecp config get --query 'objects.gateway_ssl_cert_info' --output json

if [[ -f generated/cert.pem ]] && [[ -f generated/key.pem ]]; then
   echo "Setting up Gateway SSL certificate and key"
   hpecp install set-gateway-ssl --cert-file generated/cert.pem --key-file generated/key.pem

   GATEWAY_SSL_CONFIGURED=$(hpecp config get --query 'objects.gateway_ssl_cert_info | length(@)' --output json)
   if [[ ${GATEWAY_SSL_CONFIGURED} == 0 ]]; then
      echo "Gateway SSL was not configured. Aborting."
      exit 1
   fi
fi

echo "SSL info:"
hpecp config get --query 'objects.gateway_ssl_cert_info' --output json

echo "Removing locks"
hpecp lock delete-all --timeout-secs 1200

