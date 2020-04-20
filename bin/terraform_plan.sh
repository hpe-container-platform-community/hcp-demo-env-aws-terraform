#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh

terraform plan -var-file=etc/bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" \
   -out terraform-plan-$(date +"%Y_%m_%d_%I_%M_%p").out

