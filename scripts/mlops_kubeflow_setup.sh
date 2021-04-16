#!/bin/bash

exec > >(tee -i generated/log-$(basename $0).txt)
exec 2>&1

set -e # abort on error
set -u # abort on undefined variable
set -o pipefail # abort on subprocess failure

source "./scripts/variables.sh"
source "./scripts/functions.sh"

# if [[ "$EMBEDDED_DF" == "False" ]]; then
#    echo "Aborting. This script is only supported on clusters with embedded DF".
#    exit 1
# fi

WORKER_HOST_IPS=("$@")
echo "Inside script: '$0' with parameters: ${WORKER_HOST_IPS[@]}"

if [[ "${#WORKER_HOST_IPS[@]}" -lt 3 ]]; then
   
   print_header "Usage: $0 WORKER_IP_1 WORKER_IP_2 WORKER_IP_3 [ ... WORKER_IP_n ]"
   echo
   echo "The full list of worker IPs:"
   echo
   terraform output -json -state terraform.tfstate workers_private_ip
   echo
   echo "The workers that have been added to HPE CP:"
   echo
   hpecp k8sworker list
   echo
   print_header "End usage."

   exit 1
fi

print_header "Installing HPECP CLI to local machine"
export HPECP_CONFIG_FILE=generated/hpecp.conf
export HPECP_LOG_CONFIG_FILE=${PWD}/generated/hpecp_cli_logging.conf
pip3 uninstall --quiet -y hpecp || true # uninstall if exists
pip3 install --user --upgrade --quiet hpecp

HPECP_VERSION=$(hpecp config get --query 'objects.[bds_global_version]' --output text)
echo "HPECP Version: ${HPECP_VERSION}"

if [[ "${HPECP_VERSION}" != "5.3" ]]; then
   echo "This script only supports HPE CP version 5.3"
   exit 1
fi

print_header "Setup hosts as K8s workers"
echo Using the following WORKER_HOST_IPS="${WORKER_HOST_IPS[@]}"
./bin/experimental/03_k8sworkers_add.sh "${WORKER_HOST_IPS[@]}"
QUERY="[*] | @[?contains('${WORKER_HOST_IPS[@]}', ipaddr)] | [*][_links.self.href]" 
WORKER_IDS=$(hpecp k8sworker list --query "${QUERY}" --output text | tr '\n' ' ')

echo Using the following WORKER_IDS="${WORKER_IDS[@]}"

print_header "Create MLOPS cluster and tenant"
./bin/experimental/mlops_with_kubeflow_create.sh $WORKER_IDS
