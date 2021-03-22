#!/bin/bash

set -u
set -e
set -o pipefail

# Three hosts are required for the KF demo - let's select the first three from terraform
MASTER_HOSTS_INDEX='0:3'
WORKER_HOSTS_INDEX='3:'

./bin/terraform_destroy_accept.sh
./bin/create_new_environment_from_scratch.sh
bash etc/postcreate_core.sh_template

MASTER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $MASTER_HOSTS_INDEX)
WORKER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $WORKER_HOSTS_INDEX)

./bin/experimental/03_k8sworkers_add.sh $MASTER_HOSTS
./bin/experimental/03_k8sworkers_add_with_picasso_tag.sh $WORKER_HOSTS

