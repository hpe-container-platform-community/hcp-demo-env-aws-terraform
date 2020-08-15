#!/bin/bash

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
hpecp license platform-id

AVAIL_K8S_WORKERS=($(hpecp k8sworker list --query "[?status == 'ready'][_links.self.href]" --output text))

K8S_WORKER_1=${AVAIL_K8S_WORKERS[0]}
K8S_WORKER_2=${AVAIL_K8S_WORKERS[1]}

if [[ "$K8S_WORKER_1" == "" ]] || [[ "$K8S_WORKER_2" == "" ]];
then 
   echo "Required two K8S workers, but could not find two."
   exit 1
fi

K8S_VERSION=$(hpecp k8scluster k8s-supported-versions --major-filter 1 --minor-filter 17 --output text)

CLUSTER_ID=$(hpecp k8scluster create --name c1 --k8s-version $K8S_VERSION --k8shosts-config $K8S_WORKER_1:master,$K8S_WORKER_2:worker --addons [istio])
hpecp k8scluster wait-for-status --id $CLUSTER_ID --status [ready] --timeout-secs 1200

hpecp k8scluster add-addons --id $CLUSTER_ID --addons [harbor]
hpecp k8scluster wait-for-status --id $CLUSTER_ID --status [ready] --timeout-secs 1200

TENANT_ID=$(hpecp tenant create --name tenant1 --description "dev tenant" --k8s-cluster-id $CLUSTER_ID  --tenant-type k8s)

hpecp tenant wait-for-status --id $TENANT_ID --status [ready] --timeout-secs 1200

ADMIN_GROUP="CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com"
ADMIN_ROLE=$(hpecp role list  --query "[?label.name == 'Admin'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id $TENANT_ID --group $ADMIN_GROUP --role-id $ADMIN_ROLE

MEMBER_GROUP="CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com"
MEMBER_ROLE=$(hpecp role list  --query "[?label.name == 'Member'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id $TENANT_ID --group $MEMBER_GROUP --role-id $MEMBER_ROLE

