#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh

if [[ -f terraform.tfstate ]];
then
   echo "********************************************************************************************************"
   echo "Refusing to create environment because existing ./terraform.tfstate file found."
   echo "Please destroy your environment (./bin/terraform_destroy.sh) and then remove all terraform.tfstate files"
   echo "before trying again."
   echo "********************************************************************************************************"
   exit 1
fi

if [[ ! -f  "./generated/controller.prv_key" ]]; then
   [[ -d "./generated" ]] || mkdir generated
   ssh-keygen -m pem -t rsa -N "" -f "./generated/controller.prv_key"
   mv "./generated/controller.prv_key.pub" "./generated/controller.pub_key"
fi


terraform apply -var-file=etc/bluedata_infra.tfvars -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" -auto-approve=true
sleep 60

terraform output -json > generated/output.json
./scripts/post_refresh_or_apply.sh
./scripts/bluedata_install.sh 

sleep 240

./scripts/end_user_scripts/mapr_ldap/1_setup_epic_mapr_sssd.sh
./scripts/end_user_scripts/mapr_ldap/2_setup_ubuntu_mapr_sssd_and_mapr_client.sh
./scripts/end_user_scripts/mapr_ldap/3_setup_datatap.sh


