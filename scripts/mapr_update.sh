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
# Test SSH connectivity to EC2 instances from local machine
###############################################################################

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} 'echo CONTROLLER: $(hostname)'

for MAPR_CLUSTER_HOST in ${MAPR_CLUSTER_HOSTS_PUB_IPS[@]}; do 
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_CLUSTER_HOST} << ENDSSH
   sudo chmod -x /etc/update-motd.d/*
   touch .hushlogin
   echo MAPR_CLUSTER_HOST: \$(hostname)
ENDSSH
done

###############################################################################
# Setup SSH keys for passwordless SSH
###############################################################################

# We have password SSH access from our local machines to EC2, so we can utiise this to copy the Controller SSH key to each Worker
for MAPR_CLUSTER_HOST in ${MAPR_CLUSTER_HOSTS_PUB_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat /home/centos/.ssh/id_rsa.pub" | \
        ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_CLUSTER_HOST} "cat >> /home/ubuntu/.ssh/authorized_keys"
done

# test passwordless SSH connection from Controller to Workers
for MAPR_CLUSTER_HOST in ${MAPR_CLUSTER_HOSTS_PRV_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
        echo CONTROLLER: Connecting to MAPR_CLUSTER_HOST ${MAPR_CLUSTER_HOST}...
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -T ubuntu@${MAPR_CLUSTER_HOST} "echo Connected to ${MAPR_CLUSTER_HOST}!"
ENDSSH
done

# test passwordless SSH connection from Controller to Workers
for MAPR_CLUSTER_HOST in ${MAPR_CLUSTER_HOSTS_PUB_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_CLUSTER_HOST} << ENDSSH
        sudo apt-get -qq update 
        sudo apt-get -qq install -y openjdk-8-jdk python-pymysql python3-pymysql
ENDSSH
done

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

