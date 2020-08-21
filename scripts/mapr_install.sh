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
# Install MAPR
###############################################################################

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
   set -e
   set -x

   REPO_DIR="\${PWD}/mapr-ansible-cluster-${CLUSTER_ID}"
   echo REPO_DIR=\$REPO_DIR

   rm -rf \$REPO_DIR
   git clone https://github.com/hpe-container-platform-community/hcp-demo-env-aws-terraform-mapr-ansible \$REPO_DIR

   sed -i 's/cluster_name: demo.mapr.com/cluster_name: demo${CLUSTER_ID}.mapr.com/g' \$REPO_DIR/group_vars/all
   sed -i '26i\ \ when: inventory_hostname == groups["mapr-spark-yarn"][0]' \$REPO_DIR/roles/mapr-spark-yarn-install/tasks/main.yml
   sed -i 's/yarn_spark_shuffle: True/yarn_spark_shuffle: False/g' \$REPO_DIR/group_vars/all

   cp -f \$REPO_DIR/myhosts/hosts_3nodes hosts_cluster_${CLUSTER_ID}.xml

   sed -i s/10.0.0.114/${MAPR_CLUSTER_HOSTS_PRV_IPS[0]}/g ./hosts_cluster_${CLUSTER_ID}.xml
   sed -i s/10.0.0.150/${MAPR_CLUSTER_HOSTS_PRV_IPS[1]}/g ./hosts_cluster_${CLUSTER_ID}.xml
   sed -i s/10.0.0.162/${MAPR_CLUSTER_HOSTS_PRV_IPS[2]}/g ./hosts_cluster_${CLUSTER_ID}.xml
   sed -i s/ansible_user=ec2-user/ansible_user=ubuntu/g ./hosts_cluster_${CLUSTER_ID}.xml
   sed -i 's^#mapr_subnets: 10.0.0.0/24^mapr_subnets: $VPC_CIDR_BLOCK^g' ./hosts_cluster_${CLUSTER_ID}.xml

   cp ~/.ssh/id_rsa .

   rm -f ansible_log_${CLUSTER_ID}.txt

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
      -vvv \
      -k | tee ansible_log_${CLUSTER_ID}.txt
      
ENDSSH

