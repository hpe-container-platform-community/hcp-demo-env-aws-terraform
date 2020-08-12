#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/variables.sh"

echo PROJECT_DIR="${PROJECT_DIR}"
echo VPC_CIDR_BLOCK=${VPC_CIDR_BLOCK}
echo LOCAL_SSH_PRV_KEY_PATH=${LOCAL_SSH_PRV_KEY_PATH}
echo CTRL_PUB_IP=$CTRL_PUB_IP
echo MAPR_HOSTS_PRV_IPS=${MAPR_HOSTS_PRV_IPS[@]}
echo MAPR_HOSTS_PUB_IPS=${MAPR_HOSTS_PUB_IPS[@]}

###############################################################################
# Test SSH connectivity to EC2 instances from local machine
###############################################################################

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} 'echo CONTROLLER: $(hostname)'

for MAPR_HOST in ${MAPR_HOSTS_PUB_IPS[@]}; do 
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_HOST} << ENDSSH
   sudo chmod -x /etc/update-motd.d/*
   touch .hushlogin
   echo MAPR_HOST: $(hostname)
ENDSSH
done

###############################################################################
# Setup SSH keys for passwordless SSH
###############################################################################

# We have password SSH access from our local machines to EC2, so we can utiise this to copy the Controller SSH key to each Worker
for MAPR_HOST in ${MAPR_HOSTS_PUB_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat /home/centos/.ssh/id_rsa.pub" | \
        ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_HOST} "cat >> /home/ubuntu/.ssh/authorized_keys"
done

# test passwordless SSH connection from Controller to Workers
for MAPR_HOST in ${MAPR_HOSTS_PRV_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
        echo CONTROLLER: Connecting to MAPR_HOST ${MAPR_HOST}...
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -T ubuntu@${MAPR_HOST} "echo Connected to ${MAPR_HOST}!"
ENDSSH
done

# test passwordless SSH connection from Controller to Workers
for MAPR_HOST in ${MAPR_HOSTS_PUB_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_HOST} << ENDSSH
        sudo apt-get update 
        sudo apt-get install -y openjdk-8-jdk python-pymysql python3-pymysql
ENDSSH
done

###############################################################################
# Install MAPR
###############################################################################

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
   set -x
   set -e

   if [[ ! -d ~/mapr-ansible ]]; then
      git clone https://github.com/hpe-container-platform-community/hcp-demo-env-aws-terraform-mapr-ansible mapr-ansible
      sed -i '26i\ \ when: inventory_hostname == groups["mapr-spark-yarn"][0]' ./mapr-ansible/roles/mapr-spark-yarn-install/tasks/main.yml
      sed -i 's/yarn_spark_shuffle: True/yarn_spark_shuffle: False/g' ./mapr-ansible/group_vars/all
   fi

   cp -f mapr-ansible/myhosts/hosts_3nodes hosts_cluster.xml

   sed -i s/10.0.0.114/${MAPR_HOSTS_PRV_IPS[0]}/g ./hosts_cluster.xml
   sed -i s/10.0.0.150/${MAPR_HOSTS_PRV_IPS[1]}/g ./hosts_cluster.xml
   sed -i s/10.0.0.162/${MAPR_HOSTS_PRV_IPS[2]}/g ./hosts_cluster.xml
   sed -i s/ansible_user=ec2-user/ansible_user=ubuntu/g ./hosts_cluster.xml
   sed -i 's^#mapr_subnets: 10.0.0.0/24^mapr_subnets: $VPC_CIDR_BLOCK^g' ./hosts_cluster.xml

   cp ~/.ssh/id_rsa .

   docker run \
      -v \$PWD:/app \
      -w /app \
      -e ANSIBLE_HOST_KEY_CHECKING=False \
      lexauw/ansible-alpine:latest \
      ansible-playbook ./mapr-ansible/site-cluster.yml \
      -i ./hosts_cluster.xml \
      -u ubuntu \
      -become \
      -vvv \
      --key-file ./id_rsa \
      -k | tee ansible_log.txt
      
ENDSSH

