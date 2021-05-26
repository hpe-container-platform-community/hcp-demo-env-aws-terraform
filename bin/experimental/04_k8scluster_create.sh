#!/bin/bash 

set -e
set -u

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

pip3 install --quiet --upgrade --user hpecp

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
echo "Platform ID: $(hpecp license platform-id)"

MASTER_IDS="${@:1:1}"  # FIRST ARGUMENT
WORKER_IDS=("${@:2}")  # REMAINING ARGUMENTS

if [[ $MASTER_IDS =~ ^\/api\/v2\/worker\/k8shost\/[0-9]*$ ]] && [[ ${WORKER_IDS[0]} =~ ^\/api\/v2\/worker\/k8shost\/[0-9]*$ ]]; 
then
   echo "Running script: $0 $@"
else
   echo "Usage: $0 /api/v2/worker/k8shost/[0-9] /api/v2/worker/k8shost/[0-9] [ ... /api/v2/worker/k8shost/NNN ]"
   exit 1
fi

K8S_HOST_CONFIG="$(echo $MASTER_IDS | sed 's/ /:master,/g'):master,$(echo ${WORKER_IDS[@]} | sed 's/ /:worker,/g'):worker"
echo K8S_HOST_CONFIG=$K8S_HOST_CONFIG

K8S_VERSION=$(hpecp k8scluster k8s-supported-versions --major-filter 1 --minor-filter 17 --output text)

if [[ -z "$K8S_VERSION" ]]; then
   K8S_VERSION_OPT=""
else
   K8S_VERSION_OPT="--k8s-version $K8S_VERSION"
fi

echo "Creating k8s cluster with version ${K8S_VERSION} and addons=[istio] | timeout=1800s"
CLUSTER_ID=$(hpecp k8scluster create --name c1 $K8S_VERSION_OPT --k8shosts-config "$K8S_HOST_CONFIG" --addons [istio])

echo "$CLUSTER_ID"

hpecp k8scluster wait-for-status --id $CLUSTER_ID --status [ready] --timeout-secs 3600
echo "K8S cluster created successfully - ID: ${CLUSTER_ID}"

echo "Creating tenant"
TENANT_ID=$(hpecp tenant create --name "k8s-tenant-1" --description "dev tenant" --k8s-cluster-id $CLUSTER_ID  --tenant-type k8s)
hpecp tenant wait-for-status --id $TENANT_ID --status [ready] --timeout-secs 1800
echo "K8S tenant created successfully - ID: ${TENANT_ID}"

ADMIN_GROUP="CN=${AD_ADMIN_GROUP},CN=Users,DC=samdom,DC=example,DC=com"
ADMIN_ROLE=$(hpecp role list  --query "[?label.name == 'Admin'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id "$TENANT_ID" --group "$ADMIN_GROUP" --role-id "$ADMIN_ROLE"

MEMBER_GROUP="CN=${AD_MEMBER_GROUP},CN=Users,DC=samdom,DC=example,DC=com"
MEMBER_ROLE=$(hpecp role list  --query "[?label.name == 'Member'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id "$TENANT_ID" --group "$MEMBER_GROUP" --role-id "$MEMBER_ROLE"

echo "Configured tenant with AD groups Admins=${AD_ADMIN_GROUP}... and Members=${AD_MEMBER_GROUP}..."
