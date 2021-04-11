#!/bin/bash 

set -e
set -o pipefail

if [[ -z $1 ]]; then
  echo Usage: $0 WORKER_ID
  echo Where: WORKER_ID = /api/v2/worker/k8shost/[0-9]*
  exit 1
fi

set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

export WORKER_ID=$1

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

FOUND_ID=$(hpecp k8sworker list --query "[?_links.self.href == '$WORKER_ID'] | [0] | [_links.self.href]" --output text)

if [[ ! $FOUND_ID =~ ^\/api\/v2\/worker\/k8shost\/[0-9]* ]];
then
  echo "Aborting. K8S WORKER $WORKER_ID not found."
  exit 1
fi

hpecp k8sworker delete --id $WORKER_ID

echo '
Delete submitted.  To check progress run:

export HPECP_CONFIG_FILE="./generated/hpecp.conf"
hpecp k8sworker list
'