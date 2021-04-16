#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh

terraform refresh -var-file=etc/bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ipinfo.io/ip)/32"

terraform output -json > generated/output.json
./scripts/post_refresh_or_apply.sh

source ./scripts/variables.sh
if [[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" ]]; then
   # Display RDP Endpoint and Credentials
   ./generated/rdp_credentials.sh
fi
