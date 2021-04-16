#!/bin/bash 

set -e
set -u

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh


ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" ubuntu@$RDP_PUB_IP <<ENDSSH

    set -x

    CLUSTERNAME=c1
    KUBECONFIG=~/kubeconfig_c1.conf
    ./get_admin_kubeconfig.sh \$CLUSTERNAME > \$KUBECONFIG
    
    export KUBECONFIG=~/kubeconfig_c1.conf
    
    velero create backup c1 --wait
    
ENDSSH

