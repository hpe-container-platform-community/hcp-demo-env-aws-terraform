#!/bin/bash

set -u
set -e
set -o pipefail

# select the first three ECP worker hosts from terraform as the k8s masters
MASTER_HOSTS_INDEX='0:3'

# select the remaining ECP worker host hosts from terraform as the k8s workers
WORKER_HOSTS_INDEX='3:'

# verify terraform isn't deploying ECP  with embedded DF
if grep '^\s*embedded_df\s*=\s*true\s*' etc/bluedata_infra.tfvars;
then
   echo "'embedded_df' must be set to 'false' in 'etc/bluedata_infra.tfvars'"
   exit 1
fi

# start from a clean slate - remove all trace of previous runs
./bin/terraform_destroy_accept.sh

# create AWS infra and install  ECP
./bin/create_new_environment_from_scratch.sh

# perform post ECP installation setup (add gateways, etc)
bash etc/postcreate_core.sh_template

# select the IP addresses of the k8s hosts
MASTER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $MASTER_HOSTS_INDEX)
WORKER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $WORKER_HOSTS_INDEX)

# Add ECP workers without tags
./bin/experimental/03_k8sworkers_add.sh $MASTER_HOSTS

# Add ECP workers with picasso tags
./bin/experimental/03_k8sworkers_add_with_picasso_tag.sh $WORKER_HOSTS

QUERY="[*] | @[?contains('${MASTER_HOSTS}', ipaddr)] | [*][_links.self.href]"
MASTER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')

QUERY="[*] | @[?contains('${WORKER_HOSTS}', ipaddr)] | [*][_links.self.href]"
WORKER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')

K8S_VERSION=$(hpecp k8scluster k8s-supported-versions --major-filter 1 --minor-filter 20 --output text)

AD_SERVER_PRIVATE_IP=$(terraform output ad_server_private_ip)

EXTERNAL_IDENTITY_SERVER="{\"bind_pwd\":\"5ambaPwd@\",\"user_attribute\":\"CN\",\"bind_type\":\"search_bind\",\"bind_dn\":\"cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com\",\"host\":\"${AD_SERVER_PRIVATE_IP}\",\"group_attribute\":\"member\",\"security_protocol\":\"ldaps\",\"base_dn\":\"CN=Users,DC=samdom,DC=example,DC=com\",\"verify_peer\":false,\"type\":\"Active Directory\",\"port\":636}"

K8S_HOST_CONFIG="$(echo $MASTER_IDS | sed 's/ /:master,/g'):master,$(echo $WORKER_IDS | sed 's/ /:worker,/g'):worker"
echo K8S_HOST_CONFIG=$K8S_HOST_CONFIG

echo "Creating k8s cluster with version ${K8S_VERSION}"
CLUSTER_ID=$(hpecp k8scluster create --name c1 --k8s-version $K8S_VERSION --k8shosts-config "$K8S_HOST_CONFIG" --external-identity-server "${EXTERNAL_IDENTITY_SERVER}" --external-groups '["CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com","CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com"]' --datafabric true --datafabric-name=dfdemo)

echo CONTROLLER URL: $(terraform output controller_public_url)

date
echo "Waiting up to 1 hour for status == error|ready"
hpecp k8scluster wait-for-status '[error,ready]' --id $CLUSTER_ID --timeout-secs 3600
date

hpecp k8scluster list

hpecp config get | grep  bds_global_
