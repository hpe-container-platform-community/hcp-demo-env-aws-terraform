#!/bin/bash 

set -e


if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

if [[ -z $1 ]]; then
  echo Usage: $0 CLUSTER_NAME
  exit 1
fi

export CLUSTER_NAME=$1

set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh


ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" ubuntu@$RDP_PUB_IP <<ENDSSH

    set -x

    KUBECONFIG=~/kubeconfig_$CLUSTER_NAME.conf
    ./get_admin_kubeconfig.sh $CLUSTER_NAME > \$KUBECONFIG
    
    export KUBECONFIG=~/kubeconfig_$CLUSTER_NAME.conf
    
    velero create backup $CLUSTER_NAME --wait
    
ENDSSH

