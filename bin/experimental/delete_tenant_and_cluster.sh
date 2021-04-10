#!/bin/bash 

set -e
set -o pipefail

if [[ -z $1 ]]; then
  echo Usage: $0 TENANT_ID
  echo Where: TENANT_ID = /api/v1/tenant/[0-9]*
  exit 1
fi

set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

export TENANT_ID=$1

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

FOUND_ID=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [_links.self.href]" --output text)

if [[ ! $FOUND_ID =~ ^\/api\/v1\/tenant\/[0-9]* ]];
then
  echo "Aborting. Tenant $TENANT_ID not found."
  exit 1
fi

export CLUSTER_ID=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [_links.k8scluster]" --output text)

if [[ $CLUSTER_ID =~ ^\/api\/v2\/k8scluster\/[0-9]* ]];
then
  hpecp tenant delete --id $TENANT_ID --wait-for-delete-sec 1800 # 30 minutes
  hpecp k8scluster delete --id $CLUSTER_ID --wait-for-delete-sec 1800 # 30 minutes
else
  echo ""
fi