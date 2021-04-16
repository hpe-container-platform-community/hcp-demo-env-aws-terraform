#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh

if [[ ! -f  "./generated/controller.prv_key" ]]; then
   [[ -d "./generated" ]] || mkdir generated
   ssh-keygen -m pem -t rsa -N "" -f "./generated/controller.prv_key"
   mv "./generated/controller.prv_key.pub" "./generated/controller.pub_key"
   chmod 600 "./generated/controller.prv_key"
fi

terraform plan -var-file=etc/bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ipinfo.io/ip)/32" \
   -out terraform-plan-$(date +"%Y_%m_%d_%I_%M_%p").out

