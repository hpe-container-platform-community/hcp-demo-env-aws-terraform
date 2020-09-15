#!/usr/bin/env bash

CLUSTER_ID=$1

if [[ -z $CLUSTER_ID ]]; then
    echo Usage: $0 CLUSTER-ID 
    echo        CLUSTER-ID can be 1 or 2
    exit 1
fi

set -e # abort on error
set -u # abort on undefined variable


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/variables.sh"

echo PROJECT_DIR="${PROJECT_DIR}"
echo VPC_CIDR_BLOCK=${VPC_CIDR_BLOCK}
echo LOCAL_SSH_PRV_KEY_PATH=${LOCAL_SSH_PRV_KEY_PATH}
echo CTRL_PUB_IP=$CTRL_PUB_IP

if [[ ${CLUSTER_ID} == 1 ]]; then
    MAPR_CLUSTER_HOSTS_PRV_IPS=(${MAPR_CLUSTER1_HOSTS_PRV_IPS[@]})
    MAPR_CLUSTER_HOSTS_PUB_IPS=(${MAPR_CLUSTER1_HOSTS_PUB_IPS[@]})
elif [[ ${CLUSTER_ID} == 2 ]]; then
    MAPR_CLUSTER_HOSTS_PRV_IPS=(${MAPR_CLUSTER2_HOSTS_PRV_IPS[@]})
    MAPR_CLUSTER_HOSTS_PUB_IPS=(${MAPR_CLUSTER2_HOSTS_PUB_IPS[@]})
else
    echo "Unknown CLUSTER_ID ${CLUSTER_ID}. Aborting."
    exit 1
fi

echo MAPR_CLUSTER_HOSTS_PRV_IPS=${MAPR_CLUSTER_HOSTS_PRV_IPS}
echo MAPR_CLUSTER_HOSTS_PUB_IPS=${MAPR_CLUSTER_HOSTS_PUB_IPS}

###############################################################################
# Update MAPR
###############################################################################

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
   set -e
   set -x

   REPO_DIR="\${PWD}/mapr-ansible-cluster-${CLUSTER_ID}"
   echo REPO_DIR=\$REPO_DIR

   # add -vvv to debug
   docker run \
      -v \$PWD:/app \
      -w /app \
      -e ANSIBLE_HOST_KEY_CHECKING=False \
      lexauw/ansible-alpine:latest \
      ansible-playbook ./mapr-ansible-cluster-${CLUSTER_ID}/site-cluster.yml \
      -i ./hosts_cluster_${CLUSTER_ID}.xml \
      -u ubuntu \
      -become \
      --key-file ./id_rsa \
      -k | tee ansible_log_${CLUSTER_ID}_$(date '+%Y%m%d%H%M%S').txt
      
ENDSSH

