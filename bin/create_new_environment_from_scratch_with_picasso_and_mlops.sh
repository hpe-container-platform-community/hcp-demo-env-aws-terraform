#!/bin/bash

set -u
set -e
set -o pipefail

#####

MASTER_HOSTS_INDEX='0:3'
PICASSO_WORKER_HOSTS_INDEX='3:8'
MLOPS_WORKER_HOSTS_INDEX='8:11'

################################################################################
#
# General setup
#
################################################################################

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

exec > >(tee -i generated/log-$(basename $0).txt)
exec 2>&1


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
MASTER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $MASTER_HOSTS_INDEX)
PICASSO_WORKER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $PICASSO_WORKER_HOSTS_INDEX)
MLOPS_WORKER_HOSTS=$(./bin/terraform_get_worker_hosts_private_ips_by_index.py $MLOPS_WORKER_HOSTS_INDEX)


# Add ECP workers without tags
./bin/experimental/03_k8sworkers_add.sh $MASTER_HOSTS &

# Add ECP workers with picasso tags
./bin/experimental/03_k8sworkers_add_with_picasso_tag.sh $PICASSO_WORKER_HOSTS &

# Add ECP workers without picasso tags
./bin/experimental/03_k8sworkers_add.sh $MLOPS_WORKER_HOSTS &

wait

QUERY="[*] | @[?contains('${MASTER_HOSTS}', ipaddr)] | [*][_links.self.href] | [] | sort(@)"
MASTER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')
echo MASTER_HOSTS=$MASTER_HOSTS
echo MASTER_IDS=$MASTER_IDS

QUERY="[*] | @[?contains('${PICASSO_WORKER_HOSTS}', ipaddr)] | [*][_links.self.href] | [] | sort(@)"
PICASSO_WORKER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')
echo PICASSO_WORKER_HOSTS=$PICASSO_WORKER_HOSTS
echo PICASSO_WORKER_IDS=$PICASSO_WORKER_IDS

QUERY="[*] | @[?contains('${MLOPS_WORKER_HOSTS}', ipaddr)] | [*][_links.self.href] | [] | sort(@)"
MLOPS_WORKER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')
echo MLOPS_WORKER_HOSTS=$MLOPS_WORKER_HOSTS
echo MLOPS_WORKER_IDS=$MLOPS_WORKER_IDS

K8S_VERSION=$(hpecp k8scluster k8s-supported-versions --major-filter 1 --minor-filter 20 --output text)

AD_SERVER_PRIVATE_IP=$(terraform output ad_server_private_ip)

K8S_HOST_CONFIG="$(echo $MASTER_IDS | sed 's/ /:master,/g'):master,$(echo $PICASSO_WORKER_IDS $MLOPS_WORKER_IDS | sed 's/ /:worker,/g'):worker"
echo K8S_HOST_CONFIG=$K8S_HOST_CONFIG

EXTERNAL_GROUPS=$(echo '["CN=AD_ADMIN_GROUP,CN=Users,DC=samdom,DC=example,DC=com","CN=AD_MEMBER_GROUP,CN=Users,DC=samdom,DC=example,DC=com"]' \
    | sed s/AD_ADMIN_GROUP/${AD_ADMIN_GROUP}/g \
    | sed s/AD_MEMBER_GROUP/${AD_MEMBER_GROUP}/g)

echo "Creating k8s cluster with version ${K8S_VERSION}"
CLUSTER_ID=$(hpecp k8scluster create \
   --name dfcluster \
   --k8s-version $K8S_VERSION \
   --k8shosts-config "$K8S_HOST_CONFIG" \
   --addons '["kubeflow","picasso-compute"]' \
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


echo "Creating tenant"
TENANT_ID=$(hpecp tenant create --name "k8s-tenant-1" --description "MLOPS Example" --k8s-cluster-id $CLUSTER_ID  --tenant-type k8s --features '{ ml_project: true }' --quota-cores 1000)
hpecp tenant wait-for-status --id $TENANT_ID --status [ready] --timeout-secs 1800
echo "K8S tenant created successfully - ID: ${TENANT_ID}"
echo TENANT_ID=$TENANT_ID

TENANT_NS=$(hpecp tenant get $TENANT_ID | grep "^namespace: " | cut -d " " -f 2)
echo TENANT_NS=$TENANT_NS

ADMIN_GROUP="CN=${AD_ADMIN_GROUP},CN=Users,DC=samdom,DC=example,DC=com"
ADMIN_ROLE=$(hpecp role list  --query "[?label.name == 'Admin'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id "$TENANT_ID" --group "$ADMIN_GROUP" --role-id "$ADMIN_ROLE"

MEMBER_GROUP="CN=${AD_MEMBER_GROUP},CN=Users,DC=samdom,DC=example,DC=com"
MEMBER_ROLE=$(hpecp role list  --query "[?label.name == 'Member'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id "$TENANT_ID" --group "$MEMBER_GROUP" --role-id "$MEMBER_ROLE"

echo "Configured tenant with AD groups Admins=${AD_ADMIN_GROUP}... and Members=${AD_MEMBER_GROUP}..."

echo "Setting up Gitea server"
./bin/experimental/gitea_setup.sh $TENANT_ID apply

echo "Setting up MLFLOW cluster"
./bin/experimental/mlflow_cluster_create.sh $TENANT_ID

echo "Setting up Notebook"
./bin/experimental/setup_notebook.sh $TENANT_ID

echo "Waiting for mlflow KD app to have state==configured"
./bin/experimental/minio_wait_for_mlflow_configured_state.sh $TENANT_ID mlflow

echo "Retrieving minio gateway host and port"
MINIO_HOST_AND_PORT="$(./bin/experimental/minio_get_gw_host_and_port.sh $TENANT_ID mlflow)"
echo MINIO_HOST_AND_PORT=$MINIO_HOST_AND_PORT

echo "Creating minio bucket"
./bin/experimental/minio_create_bucket.sh "$MINIO_HOST_AND_PORT"

echo "Verifying KubeFlow"
./bin/experimental/verify_kf.sh $TENANT_ID



################################################################################
#
# Standalone DF setup
#
################################################################################


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

################################################################################
#
# RDP Credentials
#
################################################################################


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