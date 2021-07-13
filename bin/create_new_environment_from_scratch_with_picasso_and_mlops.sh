#!/bin/bash

exec > >(tee -i generated/log-$(basename $0).txt)
exec 2>&1

set -u
set -e
set -o pipefail

#####

PICASSO_MASTER_HOSTS_INDEX='0:3'

PICASSO_WORKER_HOSTS_INDEX='3:8'

MLOPS_HOSTS_INDEX='8:13'

################################################################################
#
# General setup
#
################################################################################

set -x
set -u
set -e
set -o pipefail

pip3 install --quiet --upgrade --user hpecp

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
echo "Platform ID: $(hpecp license platform-id)"

# verify terraform isn't deploying ECP  with embedded DF
if grep '^\s*embedded_df\s*=\s*true\s*' etc/bluedata_infra.tfvars;
then
   echo "'embedded_df' must be set to 'false' in 'etc/bluedata_infra.tfvars'"
   exit 1
fi

BIN_NAME=hpe-cp-rhel-release-5.3
if ! grep ^epic_dl_url.*${BIN_NAME} etc/bluedata_infra.tfvars;
then
  echo "this script is only tested on ${BIN_NAME}"
  exit 1
fi

# create AWS infra and install  ECP
./bin/create_new_environment_from_scratch.sh

source "./scripts/variables.sh"
source "./scripts/functions.sh"

# perform post ECP installation setup (add gateways, etc)
bash etc/postcreate_core.sh_template


################################################################################
#
# Picasso setup
#
################################################################################

# select the IP addresses of the k8s hosts
MASTER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $PICASSO_MASTER_HOSTS_INDEX)
WORKER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $PICASSO_WORKER_HOSTS_INDEX)

# Add ECP workers without tags
./bin/experimental/03_k8sworkers_add.sh $MASTER_HOSTS &

# Add ECP workers with picasso tags
./bin/experimental/03_k8sworkers_add_with_picasso_tag.sh $WORKER_HOSTS &

wait

QUERY="[*] | @[?contains('${MASTER_HOSTS}', ipaddr)] | [*][_links.self.href] | [] | sort(@)"
MASTER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')

QUERY="[*] | @[?contains('${WORKER_HOSTS}', ipaddr)] | [*][_links.self.href] | [] | sort(@)"
WORKER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')

K8S_VERSION=$(hpecp k8scluster k8s-supported-versions --major-filter 1 --minor-filter 20 --output text)

AD_SERVER_PRIVATE_IP=$(terraform output ad_server_private_ip)

K8S_HOST_CONFIG="$(echo $MASTER_IDS | sed 's/ /:master,/g'):master,$(echo $WORKER_IDS | sed 's/ /:worker,/g'):worker"
echo K8S_HOST_CONFIG=$K8S_HOST_CONFIG

EXTERNAL_GROUPS=$(echo '["CN=AD_ADMIN_GROUP,CN=Users,DC=samdom,DC=example,DC=com","CN=AD_MEMBER_GROUP,CN=Users,DC=samdom,DC=example,DC=com"]' | sed s/AD_ADMIN_GROUP/${AD_ADMIN_GROUP}/g | sed s/AD_MEMBER_GROUP/${AD_MEMBER_GROUP}/g)

echo "Creating k8s cluster with version ${K8S_VERSION}"
CLUSTER_ID=$(hpecp k8scluster create \
   --name dfcluster \
   --k8s-version $K8S_VERSION \
   --k8shosts-config "$K8S_HOST_CONFIG" \
   --ext_id_svr_bind_pwd "5ambaPwd@" \
   --ext_id_svr_user_attribute "CN" \
   --ext_id_svr_bind_type "search_bind" \
   --ext_id_svr_bind_dn "cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com" \
   --ext_id_svr_host "${AD_SERVER_PRIVATE_IP}" \
   --ext_id_svr_group_attribute "member" \
   --ext_id_svr_security_protocol "ldaps" \
   --ext_id_svr_base_dn "CN=Users,DC=samdom,DC=example,DC=com" \
   --ext_id_svr_verify_peer false \
   --ext_id_svr_type "Active Directory" \
   --ext_id_svr_port 636 \
   --external-groups "$EXTERNAL_GROUPS" \
   --datafabric true \
   --datafabric-name=dfdemo)
   
echo CLUSTER_ID=$CLUSTER_ID

echo CONTROLLER URL: $(terraform output controller_public_url)

date
echo "Waiting up to 1 hour for status == error|ready"
hpecp k8scluster wait-for-status '[error,ready]' --id $CLUSTER_ID --timeout-secs 3600
date

hpecp k8scluster list

hpecp config get | grep  bds_global_

if hpecp k8scluster list | grep ready
then
     ./bin/register_picasso.sh $CLUSTER_ID
else
     set +e
     THE_DATE=$(date +"%Y-%m-%dT%H:%M:%S%z")
     ./bin/ssh_controller.sh sudo tar czf - /var/log/bluedata/ > ${THE_DATE}-controller-logs.tar.gz
     
     for i in "${!WRKR_PUB_IPS[@]}"; do
       ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@${WRKR_PUB_IPS[$i]} sudo tar czf - /var/log/bluedata/ > ${THE_DATE}-${WRKR_PUB_IPS[$i]}-logs.tar.gz
     done
     exit 1
fi

################################################################################
#
# MLOPS setup
#
################################################################################

KF_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $MLOPS_HOSTS_INDEX)

echo KF_HOSTS="$KF_HOSTS"

# This creates a k8s cluster with KF and the spark opertor and creates a tenant named 'k8s-tenant-1'
./bin/experimental/mlops_kubeflow_setup.sh $KF_HOSTS

TENANT_ID=$(hpecp tenant list --query "[?tenant_type == 'k8s' && label.name == 'k8s-tenant-1'] | [0] | [_links.self.href]" --output text)


if [[ "$MAPR_CLUSTER1_COUNT" != "0" ]]; 
then

   print_header "Installing MAPR Cluster 1"
   CLUSTER_ID=1
   ./scripts/mapr_install.sh ${CLUSTER_ID} || true # ignore errors
   ./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh ${CLUSTER_ID} || true # ignore errors

   TENANT_ID=$(hpecp tenant list --query "[?tenant_type == 'k8s' && label.name == 'k8s-tenant-1'] | [0] | [_links.self.href]" --output text)

   print_header "Setup Datatap to external MAPR cluster 1"
   ./scripts/end_user_scripts/standalone_mapr/setup_datatap_5.1.sh $(basename $TENANT_ID)

   print_header "Setup Fuse mount on RDP host to external MAPR cluster 1"
   ./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_client.sh
fi

./bin/rdp_credentials.sh

set +x

echo
echo
 
echo "----------------------------------------------------"
echo "USER ACCOUNTS"
echo "----------------------------------------------------"
echo "Platform admin: admin/admin123"
echo "Tenant admin:   ad_admin1/pass123 (Active Directory)"
echo "Tenant member:  ad_user1/pass123  (Active Directory)"
echo "----------------------------------------------------"