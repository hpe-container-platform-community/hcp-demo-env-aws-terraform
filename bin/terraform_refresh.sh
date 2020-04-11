#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh

source "scripts/variables.sh"

terraform refresh -var-file=etc/bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32"  && \
terraform output -json > generated/output.json && \
./scripts/post_refresh_or_apply.sh


