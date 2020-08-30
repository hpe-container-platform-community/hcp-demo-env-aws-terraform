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
hpecp install get --query 'objects.gateway_ssl_cert_info' --output json

if [[ -f generated/cert.pem ]] && [[ -f generated/key.pem ]]; then
   echo "Setting up Gateway SSL certificate and key"
   CERTIFICATE=$(cat generated/cert.pem | perl -e 'while(<>) { $_ =~ s/[\r\n]/\\n/g; print "$_" }')
   KEY=$(cat generated/key.pem | perl -e 'while(<>) { $_ =~ s/[\r\n]/\\n/g; print "$_" }')
   JSON="{\"gateway_ssl_cert_info\": {\"cert_file\": {\"content\": \"${CERTIFICATE}\", \"file_name\": \"cert.pem\"}, \"key_file\": {\"content\": \"${KEY}\", \"file_name\": \"key.pem\"}}}"
   hpecp httpclient put /api/v1/install/?install_reconfig --json-file <(echo $JSON)

   GATEWAY_SSL_CONFIGURED=$(hpecp install get --query 'objects.gateway_ssl_cert_info | length(@)' --output json)
   if [[ ${GATEWAY_SSL_CONFIGURED} == 0 ]]; then
      echo "Gateway SSL was not configured. Aborting."
      exit 1
   fi
fi

echo "SSL info:"
hpecp install get --query 'objects.gateway_ssl_cert_info' --output json

echo "Removing locks"
hpecp lock delete-all --timeout-secs 1200

