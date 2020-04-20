#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh

# create private/public keys if they don't exist
if [[ ! -f  "./generated/controller.prv_key" ]]; then
   [[ -d "./generated" ]] || mkdir generated
   ssh-keygen -m pem -t rsa -N "" -f "./generated/controller.prv_key"
   mv "./generated/controller.prv_key.pub" "./generated/controller.pub_key"
   chmod 600 "./generated/controller.prv_key"
fi

terraform destroy -var-file=etc/bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" && \
rm -rf ./generated