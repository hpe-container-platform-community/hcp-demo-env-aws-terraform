#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

export HPECP_LOG_CONFIG_FILE=${PWD}/generated/hpecp_cli_logging.conf
pip3 uninstall -y hpecp || true # uninstall if exists
pip3 install --upgrade hpecp

./scripts/check_prerequisites.sh
source "scripts/functions.sh"

print_term_width '='

# while true; do
#     read -p "Do you wish to run experimental scripts y/n (enter no if unsure)? " yn
#     case $yn in
#         [Yy]* ) EXPERIMENTAL=1; break;;
#         [Nn]* ) EXPERIMENTAL=0; break;;
#         * ) echo "Please answer y or n.";;
#     esac
# done

print_header "Starting to create infrastructure with Terraform"
if [[ -f terraform.tfstate ]]; then
   TF_RESOURCES=$(cat  terraform.tfstate | python3 -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj["resources"]))')

   if [[ "$TF_RESOURCES" == "0" ]]; then
      echo "Found 0 terraform resources in terraform.tfstate - presuming this is a clean envrionment"
   else
      print_term_width '='
      echo "Refusing to create environment because existing ./terraform.tfstate file found."
      echo "Please destroy your environment (./bin/terraform_destroy.sh) and then remove all terraform.tfstate files"
      echo "before trying again."
      print_term_width '='
      exit 1
   fi
fi

if [[ ! -f  "./generated/controller.prv_key" ]]; then
   [[ -d "./generated" ]] || mkdir generated
   ssh-keygen -m pem -t rsa -N "" -f "./generated/controller.prv_key"
   mv "./generated/controller.prv_key.pub" "./generated/controller.pub_key"
   chmod 600 "./generated/controller.prv_key"
fi

terraform apply -var-file=etc/bluedata_infra.tfvars -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" -auto-approve=true

echo "Sleeping for 60s to give services a chance to startup"
sleep 60

print_header "Saving terraform output to generated/output.json"
terraform output -json > generated/output.json

print_header "Running ./scripts/post_refresh_or_apply.sh"
./scripts/post_refresh_or_apply.sh

print_header "Installing HCP"
./scripts/bluedata_install.sh

print_header "Installing HPECP CLI on Controller"
./bin/experimental/install_hpecp_cli.sh 

if [[ -f ./etc/postcreate.sh ]]; then
   print_header "Found ./etc/postcreate.sh so executing it"
   ./etc/postcreate.sh
else
   print_header "./etc/postcreate.sh not found - skipping."
fi

source "./scripts/variables.sh"
if [[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" ]]; then
   print_term_width '-'
   echo "BlueData installation completed successfully with an RDP server"
   echo "Please run ./generated/rdp_credentials.sh for connection details."
   print_term_width '-'
fi

print_term_width '-'
echo "Run ./generated/get_public_endpoints.sh for all connection details."
print_term_width '-'

print_term_width '='
