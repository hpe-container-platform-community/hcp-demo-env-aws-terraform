#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

###############################################################################
# Set variables from terraform output
###############################################################################

LOCAL_SSH_PUB_KEY_PATH=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ssh_pub_key_path"]["value"])')
LOCAL_SSH_PRV_KEY_PATH=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ssh_prv_key_path"]["value"])')

CLIENT_CIDR_BLOCK=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["client_cidr_block"]["value"])') 

EPIC_DL_URL=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epic_dl_url"]["value"])') 
EPIC_RPM_DL_URL=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epic_rpm_dl_url"]["value"])') 
EPIC_PRECHECK_DL_URL=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epic_precheck_dl_url"]["value"])') 

CTRL_PRV_IP=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_private_ip"]["value"])') 
CTRL_PUB_IP=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_public_ip"]["value"])') 

echo CTRL_PRV_IP=$CTRL_PRV_IP
echo CTRL_PUB_IP=$CTRL_PUB_IP

GATW_PRV_IP=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_private_ip"]["value"])') 
GATW_PUB_IP=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_public_ip"]["value"])') 
GATW_PRV_DNS=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_private_dns"]["value"])') 

echo GATW_PRV_IP=$GATW_PRV_IP
echo GATW_PUB_IP=$GATW_PUB_IP
echo GATW_PRV_DNS=$GATW_PRV_DNS

WRKR_PRV_IPS=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_private_ip"]["value"][0], sep=" ")') 
WRKR_PUB_IPS=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_public_ip"]["value"][0], sep=" ")') 

read -r -a WRKR_PRV_IPS <<< "$WRKR_PRV_IPS"
read -r -a WRKR_PUB_IPS <<< "$WRKR_PUB_IPS"

echo WRKR_PRV_IPS=${WRKR_PRV_IPS[@]}
echo WRKR_PUB_IPS=${WRKR_PUB_IPS[@]}

###############################################################################
# Setup error handling for debugging purposes
###############################################################################

error() {

cat << EOF
*******************************************
** AN ERROR OCCURRED RUNNING THIS SCRIPT ** 
*******************************************

You can SSH into the EC2 instances for debugging:  

CTRL SSH: ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} centos@${CTRL_PUB_IP} 
GATW SSH: ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} centos@${GATW_PUB_IP} 
EOF

  for WRKR in ${WRKR_PUB_IPS[@]}; do 
   echo WRKR [$WRKR] SSH: ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${WRKR}
  done

  echo
  exit "1"
}
trap 'error ${LINENO}' ERR

###############################################################################
# Test SSH connectivity to EC2 instances from local machine
###############################################################################

ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} 'echo CONTROLLER: $(hostname)'
ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${GATW_PUB_IP} 'echo GATEWAY: $(hostname)'

for WRKR in ${WRKR_PUB_IPS[@]}; do 
   ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${WRKR} 'echo WORKER: $(hostname)'
done

###############################################################################
# Setup SSH keys for passwordless SSH
###############################################################################

# if ssh key doesn't exist on controller EC instance then create one
ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} << ENDSSH
if [ -f ~/.ssh/id_rsa ]
then
   echo CONTROLLER: Found existing ~/.ssh/id.rsa so moving on...
else
   ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
   echo CONTROLLER: Created ~/.ssh/id_rsa
fi

# BlueData controller installer requires this
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
ENDSSH

#
# Controller -> Gateway
#

# We have password SSH access from our local machines to EC2, so we can utiise this to copy the Controller SSH key to the Gateway
ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} "cat /home/centos/.ssh/id_rsa.pub" | \
  ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${GATW_PUB_IP} "cat >> /home/centos/.ssh/authorized_keys" 

# test passwordless SSH connection from Controller to Gateway
ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} << ENDSSH
echo CONTROLLER: Connecting to GATEWAY ${GATW_PUB_IP}...
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -T centos@${GATW_PRV_IP} "echo Connected!"
ENDSSH

#
# Controller -> Workers
#

# We have password SSH access from our local machines to EC2, so we can utiise this to copy the Controller SSH key to each Worker
for WRKR in ${WRKR_PUB_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} "cat /home/centos/.ssh/id_rsa.pub" | \
        ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${WRKR} "cat >> /home/centos/.ssh/authorized_keys"
done

# test passwordless SSH connection from Controller to Workers
for WRKR in ${WRKR_PRV_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} << ENDSSH
        echo CONTROLLER: Connecting to WORKER ${WRKR}...
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -T centos@${WRKR} "echo Connected!"
ENDSSH
done

###############################################################################
# Install RPMS
###############################################################################

#
# Gateway
#

ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${GATW_PUB_IP} << ENDSSH
   curl -s -f ${EPIC_RPM_DL_URL} | grep proxy | awk '{print \$3}' | sed -r "s/([a-zA-Z0-9_+]*)(-[a-zA-Z0-9]+)?(-\S+)(-.*)/\1\2\3/" | xargs sudo yum install -y 
ENDSSH
# if the reboot causes ssh to terminate with an error, ignore it
ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${GATW_PUB_IP} "nohup sudo reboot </dev/null &" || true


#
# Controller
#

ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} << ENDSSH
   curl -s -f ${EPIC_RPM_DL_URL} | grep ctrl | awk '{print \$3}' | sed -r "s/([a-zA-Z0-9_+]*)(-[a-zA-Z0-9]+)?(-\S+)(-.*)/\1\2\3/" | xargs sudo yum install -y 
ENDSSH
# if the reboot causes ssh to terminate with an error, ignore it
ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} "nohup sudo reboot </dev/null &" || true

#
# Workers
#

for WRKR in ${WRKR_PUB_IPS[@]}; do 
   ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${WRKR} << ENDSSH
    curl -s -f ${EPIC_RPM_DL_URL} | grep wrkr | awk '{print \$3}' | sed -r "s/([a-zA-Z0-9_+]*)(-[a-zA-Z0-9]+)?(-\S+)(-.*)/\1\2\3/" | xargs sudo yum install -y 
ENDSSH
# if the reboot causes ssh to terminate with an error, ignore it
ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${WRKR} "nohup sudo reboot </dev/null &" || true
done

#
# Wait for Gateway, Controller and Workers to come online after reboot
#

echo 'Waiting for Gateway ssh session '
while ! nc -w5 -z ${GATW_PUB_IP} 22; do printf "." -n ; done;
echo 'Gateway has rebooted'

echo 'Waiting for Controller ssh session '
while ! nc -w5 -z ${CTRL_PUB_IP} 22; do printf "." -n ; done;
echo 'Controller has rebooted'

for WRKR in ${WRKR_PUB_IPS[@]}; do 
    echo "Waiting for Worker ${WRKR} ssh session"
    while ! nc -w5 -z ${WRKR} 22; do printf "." -n ; done;
    echo 'Worker has rebooted'
done

###############################################################################
# Prechecks
###############################################################################

# Controller

IGNORE_CTRL_PRECHECK_FAIL=true

ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} << ENDSSH
   curl -s -o bluedata-prechecks-epic-entdoc-3.7.bin ${EPIC_PRECHECK_DL_URL}
   chmod +x bluedata-prechecks-epic-entdoc-3.7.bin

   if [ "$IGNORE_CTRL_PRECHECK_FAIL" == 'true' ];
   then
      sudo ./bluedata-prechecks-epic-entdoc-3.7.bin -c \
        --controller-ip ${CTRL_PRV_IP} \
        --gateway-node-ip ${GATW_PRV_IP} \
        --gateway-node-hostname ${GATW_PRV_DNS} || true 2>&1 > /home/centos/bluedata-precheck.log
   else
      sudo ./bluedata-prechecks-epic-entdoc-3.7.bin -c \
        --controller-ip ${CTRL_PRV_IP} \
        --gateway-node-ip ${GATW_PRV_IP} \
        --gateway-node-hostname ${GATW_PRV_DNS} || exit 1 2>&1 > /home/centos/bluedata-precheck.log
   fi
ENDSSH

# Workers

IGNORE_WRKR_PRECHECK_FAIL=true

for INDEX in ${!WRKR_PUB_IPS[@]}; do 

   WRKR_PUB_IP=${WRKR_PUB_IPS[$INDEX]}
   WRKR_PRV_IP=${WRKR_PRV_IPS[$INDEX]}

   ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${WRKR_PUB_IP} << ENDSSH
 
    # ensure drives are mounted before pre-checking
    while ! mountpoint -x /dev/xvdb; do sleep 1; done
    while ! mountpoint -x /dev/xvdc; do sleep 1; done

    curl -s -o bluedata-prechecks-epic-entdoc-3.7.bin ${EPIC_PRECHECK_DL_URL}
    chmod +x bluedata-prechecks-epic-entdoc-3.7.bin

    if [ "$IGNORE_WRKR_PRECHECK_FAIL" == 'true' ];
    then
        sudo ./bluedata-prechecks-epic-entdoc-3.7.bin -w \
            --worker-primary-ip ${WRKR_PRV_IP} \
            --controller-ip ${CTRL_PRV_IP} \
            --gateway-node-ip ${GATW_PRV_IP} \
            --gateway-node-hostname ${GATW_PRV_DNS} || true 2>&1 > /home/centos/bluedata-precheck.log
    else
        sudo ./bluedata-prechecks-epic-entdoc-3.7.bin -w \
            --worker-primary-ip ${WRKR_PRV_IP} \
            --controller-ip ${CTRL_PRV_IP} \
            --gateway-node-ip ${GATW_PRV_IP} \
            --gateway-node-hostname ${GATW_PRV_DNS} || exit 1 2>&1 > /home/centos/bluedata-precheck.log
    fi
ENDSSH
done

###############################################################################
# Install Controller
###############################################################################

scp -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} initial_bluedata_config.py centos@${CTRL_PUB_IP}:/home/centos/initial_bluedata_config.py

ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} << ENDSSH
   curl -s -o bluedata-epic-entdoc-minimal-release-3.7-2207.bin ${EPIC_DL_URL}
   chmod +x bluedata-epic-entdoc-minimal-release-3.7-2207.bin

   # install EPIC
   echo "sudo ./bluedata-epic-entdoc-minimal-release-3.7-2207.bin -f -s -i -c ${CTRL_PRV_IP} --user centos --group centos"
   sudo ./bluedata-epic-entdoc-minimal-release-3.7-2207.bin -f -s -i -c ${CTRL_PRV_IP} --user centos --group centos

   # install application workbench
   sudo yum install -y epel-release
   sudo yum install -y python-pip
   sudo pip install --upgrade pip
   sudo pip install --upgrade setuptools
   sudo pip install --upgrade bdworkbench

   # automate initial configuration screen
   sudo pip install beautifulsoup4
   sudo pip install lxml

   # Accept the defaults on the first configuration screen after installing BlueData
   python /home/centos/initial_bluedata_config.py
ENDSSH

###############################################################################
# Manually configure Controller with Workers and Gateway
###############################################################################

echo "** BlueData installation completed successfully.  You now need to configure it **"
echo "Controller URL: http://${CTRL_PUB_IP} - login: admin/admin123"
echo "Worker IPs: ${WRKR_PRV_IP[@]}"
echo "Gateway IP: ${GATW_PRV_IP}"   # should this be the public IP?
echo "Gateway DNS: ${GATW_PRV_DNS}" # should this be the public DNS?

echo "Downloading Controller SSH Private key to 'controller.prv_key' ** PLEASE KEEP IT SECURE **"
ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} centos@${CTRL_PUB_IP} 'cat ~/.ssh/id_rsa' > controller.prv_key

cat << EOF
Instructions:

1. At the login screen, use 'admin/admin123'
2. Navigate to Installation tab
   1. Add workers private ip ${WRKR_PRV_IP[@]} 
   2. Add gateway private ip and private dns ${GATW_PRV_IP} | ${GATW_PRV_DNS}
   3. Upload controller.prv_key
   4. Click Add hosts (enter site lock down when prompted)

   # After a few minutes, you should see Gateway 'Installed' and Workers 'Bundle completed'

   5. Select each Worker
   6. Click 'Install'
   7. Wait a few minutes
EOF

