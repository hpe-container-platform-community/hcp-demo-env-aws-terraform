#!/bin/bash

set -e # abort on error

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

pip3 install --quiet --upgrade git+https://github.com/hpe-container-platform-community/hpecp-client@master

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
hpecp license platform-id

AVAIL_K8S_WORKERS=($(hpecp k8sworker list --columns [id,status] --output text | awk '$2 == "ready" { print $1 }' | tr '\r\n' ' '))

K8S_WORKER_1=${AVAIL_K8S_WORKERS[0]}
K8S_WORKER_2=${AVAIL_K8S_WORKERS[1]}

if [[ "$K8S_WORKER_1" == "" ]] || [[ "$K8S_WORKER_2" == "" ]];
then 
   echo "Required two K8S workers, but could not find two."
   exit 1
fi

K8S_VERSION=$(hpecp k8scluster k8s-supported-versions --major-filter 1 --minor-filter 17 --output text)

CLUSTER_ID=$(hpecp k8scluster create --name c1 --k8s-version $K8S_VERSION --k8shosts-config $K8S_WORKER_1:master,$K8S_WORKER_2:worker)

hpecp k8scluster wait-for-status --id $CLUSTER_ID --status [ready] --timeout-secs 600

