#!/bin/bash 

set -e
set -o pipefail

if [[ -z $1 ]]; then
  echo Usage: $0 CLUSTER_ID
  echo Where: CLUSTER_ID = /api/v2/k8scluster/[0-9]*
  exit 1
fi

set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

export TENANT_ID=$1

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

FOUND_ID=$(hpecp k8scluster list --query "[?_links.self.href == '$CLUSTER_ID'] | [0] | [_links.self.href]" --output text)

if [[ ! $FOUND_ID =~ ^\/api\/v2\/k8scluster\/[0-9]* ]];
then
  echo "Aborting. Tenant $CLUSTER_ID not found."
  exit 1
fi

hpecp k8scluster delete --id $CLUSTER_ID

echo '
Delete submitted.  To check progress run:

export HPECP_CONFIG_FILE="./generated/hpecp.conf"
hpecp k8scluster list
'