#!/bin/bash

set -u
set -e
set -o pipefail

if grep '^\s*embedded_df\s*=\s*false\s*' etc/bluedata_infra.tfvars; 
then
   echo "'embedded_df' must be set to 'true' in 'etc/bluedata_infra.tfvars'"
   exit 1
fi

if [[ $(grep ^worker_count etc/bluedata_infra.tfvars | awk '$3 > 1 {print "true"}') != "true" ]];
then
  echo "worker_count in etc/bluedata_infra.tfvars must be > 1"
  exit 1
fi

# Three hosts are required for the KF demo - let's select the first three from terraform
KF_HOSTS_INDEX='0:3'

./bin/terraform_destroy_accept.sh
./bin/create_new_environment_from_scratch.sh

KF_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $KF_HOSTS_INDEX)

echo KF_HOSTS="$KF_HOSTS"
bash etc/postcreate_core.sh_template
./scripts/mlops_kubeflow_setup.sh $KF_HOSTS

./bin/rdp_credentials.sh

echo
echo
 
echo "----------------------------------------------------"
echo "USER ACCOUNTS"
echo "----------------------------------------------------"
echo "Platform admin: admin/admin123"
echo "Tenant admin:   ad_admin1/pass123 (Active Directory)"
echo "Tenant member:  ad_user1/pass123  (Active Directory)"
echo "----------------------------------------------------"
     
