#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh
source ./scripts/functions.sh

print_term_width "="
echo "TIP: Parameters given to this script are passed to 'terraform apply'"
echo "     Example: ./bin/terraform_apply.sh -var='ad_server_enabled=false'"
print_term_width "="


if [[ ! -f  "./generated/controller.prv_key" ]]; then
   [[ -d "./generated" ]] || mkdir generated
   ssh-keygen -m pem -t rsa -N "" -f "./generated/controller.prv_key"
   mv "./generated/controller.prv_key.pub" "./generated/controller.pub_key"
   chmod 600 "./generated/controller.prv_key"
fi

if [[ ! -f  "./generated/ca-key.pem" ]]; then
   openssl genrsa -out "./generated/ca-key.pem" 2048
   openssl req -x509 \
      -new -nodes \
      -key "./generated/ca-key.pem" \
      -subj "/C=US/ST=CA/O=MyOrg, Inc./CN=mydomain.com" \
      -sha256 -days 1024 \
      -out "./generated/ca-cert.pem"
   chmod 660 "./generated/ca-key.pem"
fi

terraform apply -var-file=<(cat etc/*.tfvars) \
   -var="client_cidr_block=$(curl -s http://ipinfo.io/ip)/32" "$@"

terraform output -json > generated/output.json 
./scripts/post_refresh_or_apply.sh

source ./scripts/variables.sh
if [[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" ]]; then
   # Display RDP Endpoint and Credentials
   ./bin/rdp_credentials.sh
fi




