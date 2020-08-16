#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh
source "scripts/functions.sh"

print_term_width '='

while true; do
    read -p "Do you wish to run experimental scripts y/n (enter no if unsure)? " yn
    case $yn in
        [Yy]* ) EXPERIMENTAL=1; break;;
        [Nn]* ) EXPERIMENTAL=0; break;;
        * ) echo "Please answer y or n.";;
    esac
done

print_term_width '='

if [[ -f terraform.tfstate ]]; then
   TF_RESOURCES=$(cat  terraform.tfstate | python3 -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj["resources"]))')

   if [[ "$TF_RESOURCES" == "0" ]]; then
      echo "Found 0 terraform resources in terraform.tfstate - presuming this is a clean envrionment"
   else
      echo "********************************************************************************************************"
      echo "Refusing to create environment because existing ./terraform.tfstate file found."
      echo "Please destroy your environment (./bin/terraform_destroy.sh) and then remove all terraform.tfstate files"
      echo "before trying again."
      echo "********************************************************************************************************"
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

terraform output -json > generated/output.json

./scripts/post_refresh_or_apply.sh
./scripts/bluedata_install.sh

source ./scripts/variables.sh

if [[ "$EXPERIMENTAL" == "1" ]]; then

   if [[ "$MAPR_COUNT" == "3" ]]; then
      ./scripts/mapr_install.sh || true # ignore errors
      ./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh || true # ignore errors
   fi
   
   ./bin/experimental/install_hpecp_cli.sh # install the hpecp
   ./bin/experimental/01_configure_global_active_directory.sh
   ./bin/experimental/02_gateway_add.sh
   ./bin/experimental/setup_demo_tenant_ad.sh

   echo "Sleeping for 240s to give services a chance to startup"
   sleep 240
    
   ./scripts/end_user_scripts/embedded_mapr/1_setup_epic_mapr_sssd.sh
   ./scripts/end_user_scripts/embedded_mapr/2_setup_ubuntu_mapr_sssd_and_mapr_client.sh
   ./bin/df-cluster-acl-ad_admin1.sh # add the ad_admin1 user to the cluster
   set +e
   ./scripts/end_user_scripts/embedded_mapr/3_setup_datatap_new.sh

   print_term_width '='
   echo "Recommended scripts:"
   echo "--------------------"
   echo "./bin/experimental/epic_enable_virtual_node_assignment.sh"
   echo "./bin/experimental/epic_set_cpu_allocation_ratio.sh"
   echo "./bin/experimental/03_k8sworkers_add.sh 2 # add 2 EC2 hosts as k8s workers"
   echo "./bin/experimental/04_k8scluster_create.sh"

   if [[ "$MAPR_COUNT" == "3" ]]; then
      echo "./scripts/end_user_scripts/patch_datatap_5.1.1.sh"
      echo "./scripts/end_user_scripts/standalone_mapr/setup_datatap_5.1.sh"
   fi

   # install images last because operations requiring system to be quiesced 
   # such as site lockdown may have to wait a long time for the installs

   echo "./bin/experimental/epic_catalog_image_install_spark23.sh"
   echo "or"
   echo "./bin/experimental/epic_catalog_image_install_all.sh"
   echo "./bin/experimental/epic_catalog_image_status.sh"
   print_term_width '='

fi

if [[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" ]]; then
   echo "*******************************************************************"
   echo "BlueData installation completed successfully with an RDP server"
   echo "Please run ./generated/rdp_credentials.sh for connection details."
   echo "*******************************************************************"
fi

echo "*******************************************************************"
echo "Run ./generated/get_public_endpoints.sh for all connection details."
echo "*******************************************************************"

print_term_width '='