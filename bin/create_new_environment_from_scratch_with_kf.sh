#!/bin/bash

set -u
set -e
set -o pipefail

if grep '^\s*embedded_df\s*=\s*false\s*' etc/bluedata_infra.tfvars; 
then
   echo "'embedded_df' must be set to 'true' in 'etc/bluedata_infra.tfvars'"
   exit 1
fi

# Three hosts are required for the KF demo - let's select the first three from terraform
KF_HOSTS_INDEX='0:3'

./bin/terraform_destroy_accept.sh
./bin/create_new_environment_from_scratch.sh

KF_HOSTS=$(terraform output -json -no-color workers_private_ip | python -c "import sys, json; obj=json.load(sys.stdin);print(' '.join(obj[0][$KF_HOSTS_INDEX]))")

echo KF_HOSTS="$KF_HOSTS"
bash etc/postcreate_core.sh_template
./scripts/mlops_kubeflow_setup.sh $KF_HOSTS
