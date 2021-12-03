#!/usr/bin/env bash

set -e
set -o pipefail

if [[ -z $1 ]]; then
  echo Usage: $0 CLUSTER_ID
  echo Where: CLUSTER_ID = /api/v2/k8scluster/[0-9]*
  exit 1
fi

CLUSTER_ID=$1

set -u

source ./scripts/check_prerequisites.sh
source ./scripts/variables.sh

MASTERS=($(./bin/get_k8s_masters.sh $CLUSTER_ID))
echo MASTERS=${MASTERS[@]}

FIRST_MASTER_IP=$(./bin/get_k8s_host_ip.sh ${MASTERS[0]})
echo FIRST_MASTER_IP=$FIRST_MASTER_IP


ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
  set -x
  set -e
  
  export LOG_FILE_PATH=/tmp/register_k8s_prepare.log 
  export MASTER_NODE_IP="${FIRST_MASTER_IP}" 
  
  function retry {
    local n=1
    local max=20
    local delay=30
    while true; do
      "\$@" && break || {
        if [[ \$n -lt \$max ]]; then
          ((n++))
          echo "Command failed. Attempt \$n/\$max:"
          sleep \$delay;
        else
          fail "The command has failed after \$n attempts."
        fi
    }
    done
  }

  retry /opt/bluedata/bundles/hpe-cp-*/startscript.sh --action prepare_dftenants
ENDSSH

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
  set -x
  export LOG_FILE_PATH=/tmp/register_k8s_configure.log
  export MASTER_NODE_IP="${FIRST_MASTER_IP}"
  
  echo yes | /opt/bluedata/bundles/hpe-cp-*/startscript.sh --action configure_dftenants
ENDSSH

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
  set -x
  export LOG_FILE_PATH=/tmp/register_k8s_register.log
  export SILENT_MODE=true 
  export SITE_ADMIN_USER=admin 
  
  # FIXME !!! hardcoded password !!!
  export SITE_ADMIN_PASS=admin123 
  export MASTER_NODE_IP="${FIRST_MASTER_IP}"
  /opt/bluedata/bundles/hpe-cp-*/startscript.sh --action register_dftenants

ENDSSH