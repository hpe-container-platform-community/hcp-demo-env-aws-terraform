#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh

if [[ ! -f  "./generated/controller.prv_key" ]]; then
   [[ -d "./generated" ]] || mkdir generated
   ssh-keygen -t rsa -N "" -f "./generated/controller.prv_key"
   mv "./generated/controller.prv_key.pub" "./generated/controller.pub_key"
   chmod 600 "./generated/controller.prv_key"
fi

terraform apply -var-file=etc/bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ipinfo.io/ip)/32" -auto-approve=true "$@" && \
terraform output -json > generated/output.json && \
./scripts/post_refresh_or_apply.sh

source ./scripts/variables.sh
if [[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "Linux" ]]; then
   # Display RDP Endpoint and Credentials
   ./bin/rdp_credentials.sh
fi
