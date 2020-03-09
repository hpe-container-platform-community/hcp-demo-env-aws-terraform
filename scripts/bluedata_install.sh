#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
OUTPUT_JSON=$(cat "${SCRIPT_DIR}/../generated/output.json")

###############################################################################
# Set variables from terraform output
###############################################################################

PROJECT_DIR=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["project_dir"]["value"])')
echo PROJECT_DIR="${PROJECT_DIR}"
[ "$PROJECT_DIR" ] || ( echo "ERROR: PROJECT_DIR is empty" && exit 1 )

LOG_FILE="${PROJECT_DIR}"/generated/bluedata_install_output.txt
[[ -f "$LOG_FILE" ]] && mv -f "$LOG_FILE" "${LOG_FILE}".old

LOCAL_SSH_PUB_KEY_PATH=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ssh_pub_key_path"]["value"])')
LOCAL_SSH_PRV_KEY_PATH=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ssh_prv_key_path"]["value"])')

[ "$LOCAL_SSH_PUB_KEY_PATH" ] || ( echo "ERROR: LOCAL_SSH_PUB_KEY_PATH is empty" && exit 1 )
[ "$LOCAL_SSH_PRV_KEY_PATH" ] || ( echo "ERROR: LOCAL_SSH_PRV_KEY_PATH is empty" && exit 1 )

echo LOCAL_SSH_PUB_KEY_PATH=${LOCAL_SSH_PUB_KEY_PATH}
echo LOCAL_SSH_PRV_KEY_PATH=${LOCAL_SSH_PRV_KEY_PATH}

CA_KEY="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ca_key"]["value"])')"
CA_CERT="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ca_cert"]["value"])')"

[ "$CA_KEY" ] || ( echo "ERROR: CA_KEY is empty" && exit 1 )
[ "$CA_CERT" ] || ( echo "ERROR: CA_CERT is empty" && exit 1 )

EPIC_DL_URL="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epic_dl_url"]["value"])')"
EPIC_FILENAME="$(echo ${EPIC_DL_URL##*/} | cut -d? -f1)"
EPIC_DL_URL_NEEDS_PRESIGN="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epid_dl_url_needs_presign"]["value"])')"

echo EPIC_DL_URL=$EPIC_DL_URL
echo EPIC_FILENAME=$EPIC_FILENAME
echo EPIC_DL_URL_NEEDS_PRESIGN=$EPIC_DL_URL_NEEDS_PRESIGN

[ "$EPIC_DL_URL" ] || ( echo "ERROR: EPIC_DL_URL is empty" && exit 1 )
[ "$EPIC_FILENAME" ] || ( echo "ERROR: EPIC_FILENAME is empty" && exit 1 )
[ "$EPIC_DL_URL_NEEDS_PRESIGN" ] || ( echo "ERROR: EPIC_DL_URL_NEEDS_PRESIGN is empty" && exit 1 )

if [[ "${EPIC_DL_URL_NEEDS_PRESIGN}" == "True" ]]
then
   echo "Presigning EPIC_DL_URL"
   EPIC_DL_URL="$(aws s3 presign $EPIC_DL_URL)"
   echo ${EPIC_DL_URL}
fi

SELINUX_DISABLED="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["selinux_disabled"]["value"])')"
echo SELINUX_DISABLED=$SELINUX_DISABLED
[ "$SELINUX_DISABLED" ] || ( echo "ERROR: SELINUX_DISABLED is empty" && exit 1 )

CTRL_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_private_ip"]["value"])') 
CTRL_PUB_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_public_ip"]["value"])') 
CTRL_PRV_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_private_dns"]["value"])') 
CTRL_PUB_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_public_dns"]["value"])') 

CTRL_PUB_HOST=$(echo $CTRL_PUB_DNS | cut -d"." -f1)
CTRL_PRV_HOST=$(echo $CTRL_PRV_DNS | cut -d"." -f1)

echo CTRL_PRV_IP=$CTRL_PRV_IP
echo CTRL_PUB_IP=$CTRL_PUB_IP
echo CTRL_PRV_DNS=$CTRL_PRV_DNS
echo CTRL_PUB_DNS=$CTRL_PUB_DNS
echo CTRL_PUB_HOST=$CTRL_PUB_HOST
echo CTRL_PRV_HOST=$CTRL_PRV_HOST

[ "$CTRL_PRV_IP" ] || ( echo "ERROR: CTRL_PRV_IP is empty" && exit 1 )
[ "$CTRL_PUB_IP" ] || ( echo "ERROR: CTRL_PUB_IP is empty" && exit 1 )
[ "$CTRL_PRV_DNS" ] || ( echo "ERROR: CTRL_PRV_DNS is empty" && exit 1 )
[ "$CTRL_PUB_DNS" ] || ( echo "ERROR: CTRL_PUB_DNS is empty" && exit 1 )
[ "$CTRL_PUB_HOST" ] || ( echo "ERROR: CTRL_PUB_HOST is empty" && exit 1 )
[ "$CTRL_PRV_HOST" ] || ( echo "ERROR: CTRL_PRV_HOST is empty" && exit 1 )

GATW_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_private_ip"]["value"])') 
GATW_PUB_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_public_ip"]["value"])') 
GATW_PRV_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_private_dns"]["value"])') 
GATW_PUB_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_public_dns"]["value"])') 
GATW_PUB_HOST=$(echo $GATW_PUB_DNS | cut -d"." -f1)
GATW_PRV_HOST=$(echo $GATW_PRV_DNS | cut -d"." -f1)

echo GATW_PRV_IP=$GATW_PRV_IP
echo GATW_PUB_IP=$GATW_PUB_IP
echo GATW_PRV_DNS=$GATW_PRV_DNS
echo GATW_PUB_DNS=$GATW_PUB_DNS
echo GATW_PUB_HOST=$GATW_PUB_HOST
echo GATW_PRV_HOST=$GATW_PRV_HOST

[ "$GATW_PRV_IP" ] || ( echo "ERROR: GATW_PRV_IP is empty" && exit 1 )
[ "$GATW_PUB_IP" ] || ( echo "ERROR: GATW_PUB_IP is empty" && exit 1 )
[ "$GATW_PRV_DNS" ] || ( echo "ERROR: GATW_PRV_DNS is empty" && exit 1 )
[ "$GATW_PUB_DNS" ] || ( echo "ERROR: GATW_PUB_DNS is empty" && exit 1 )
[ "$GATW_PUB_HOST" ] || ( echo "ERROR: GATW_PUB_HOST is empty" && exit 1 )
[ "$GATW_PRV_HOST" ] || ( echo "ERROR: GATW_PRV_HOST is empty" && exit 1 )

WRKR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_private_ip"]["value"][0], sep=" ")') 
WRKR_PUB_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_public_ip"]["value"][0], sep=" ")') 

[ "$WRKR_PRV_IPS" ] || ( echo "ERROR: WRKR_PRV_IPS is empty" && exit 1 )
[ "$WRKR_PUB_IPS" ] || ( echo "ERROR: WRKR_PUB_IPS is empty" && exit 1 )

read -r -a WRKR_PRV_IPS <<< "$WRKR_PRV_IPS"
read -r -a WRKR_PUB_IPS <<< "$WRKR_PUB_IPS"

echo WRKR_PRV_IPS=${WRKR_PRV_IPS[@]}
echo WRKR_PUB_IPS=${WRKR_PUB_IPS[@]}

###############################################################################
# Test SSH connectivity to EC2 instances from local machine
###############################################################################

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} 'echo CONTROLLER: $(hostname)'
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${GATW_PUB_IP} 'echo GATEWAY: $(hostname)'

for WRKR in ${WRKR_PUB_IPS[@]}; do 
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} 'echo WORKER: $(hostname)'
done

###############################################################################
# Setup SSH keys for passwordless SSH
###############################################################################

# if ssh key doesn't exist on controller EC instance then create one
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
if [ -f ~/.ssh/id_rsa ]
then
   echo CONTROLLER: Found existing ~/.ssh/id.rsa so moving on...
else
   ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
   echo CONTROLLER: Created ~/.ssh/id_rsa
fi

# BlueData controller installer requires this - TODO only add if it doesn't already exist
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
ENDSSH

#
# Controller -> Gateway
#

# We have password SSH access from our local machines to EC2, so we can utiise this to copy the Controller SSH key to the Gateway
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat /home/centos/.ssh/id_rsa.pub" | \
  ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${GATW_PUB_IP} "cat >> /home/centos/.ssh/authorized_keys" 

# test passwordless SSH connection from Controller to Gateway
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
echo CONTROLLER: Connecting to GATEWAY ${GATW_PRV_IP}...
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -T centos@${GATW_PRV_IP} "echo Connected!"
ENDSSH

#
# Controller -> Workers
#

# We have password SSH access from our local machines to EC2, so we can utiise this to copy the Controller SSH key to each Worker
for WRKR in ${WRKR_PUB_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat /home/centos/.ssh/id_rsa.pub" | \
        ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "cat >> /home/centos/.ssh/authorized_keys"
done

# test passwordless SSH connection from Controller to Workers
for WRKR in ${WRKR_PRV_IPS[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
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

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${GATW_PUB_IP} "sudo yum update -y"
# if the reboot causes ssh to terminate with an error, ignore it
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${GATW_PUB_IP} "nohup sudo reboot </dev/null &" || true


#
# Controller
#

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "sudo yum update -y"

# FIXME: Hack to allow HPE CP httpd service to use minica key and cert
echo 'Disabling SELINUX on the Controller host'
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "sudo sed -i --follow-symlinks 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux"
# if the reboot causes ssh to terminate with an error, ignore it
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "nohup sudo reboot </dev/null &" || true

#
# Workers
#

for WRKR in ${WRKR_PUB_IPS[@]}; do 
   if [[ "$SELINUX_DISABLED" == "True" ]];
   then
      echo "Disabling SELINUX on the worker host $WRKR"
      ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo sed -i --follow-symlinks 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux"
   fi

   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo yum update -y"
   # if the reboot causes ssh to terminate with an error, ignore it
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "nohup sudo reboot </dev/null &" || true
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
# Install Controller
###############################################################################

cat generated/ca-cert.pem | ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat > ~/minica.pem"
cat generated/ca-key.pem  | ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat > ~/minica-key.pem" 

echo "SSHing into Controller ${CTRL_PUB_IP}"

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH

   if [[ -e /home/centos/bd_installed ]]
   then
      echo BlueData already installed - quitting
      exit 0
   fi

   set -e # abort on error

   sudo yum -y install git wget
   wget -c --progress=bar -e dotbytes=1M https://dl.google.com/go/go1.13.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz

   if [[ ! -d minica ]];
   then
      git clone https://github.com/jsha/minica.git
      cd minica/
      /usr/local/go/bin/go build
      sudo mv minica /usr/local/bin
   fi

   # FIXME: Currently this requires SELINUX to be disabled so apache httpd can read the certs
   rm -rf /home/centos/${CTRL_PUB_DNS}
   cd /home/centos
   minica -domains "$CTRL_PUB_DNS,$CTRL_PRV_DNS,$GATW_PUB_DNS,$GATW_PRV_DNS,$CTRL_PUB_HOST,$CTRL_PRV_HOST,$GATW_PUB_HOST,$GATW_PRV_HOST" \
      -ip-addresses "$CTRL_PUB_IP,$CTRL_PRV_IP,$GATW_PUB_IP,$GATW_PRV_IP"

   # output the ssl details for debugging purposes
   openssl x509 -in /home/centos/${CTRL_PUB_DNS}/cert.pem -text

   echo "Downloading ${EPIC_DL_URL} to ${EPIC_FILENAME}"

   wget -c --progress=bar -e dotbytes=10M -O ${EPIC_FILENAME} "${EPIC_DL_URL}"
   chmod +x ${EPIC_FILENAME}

   echo "Running EPIC install"

   # install EPIC (Note: minica puts the cert and key in a folder named after the first DNS domain)
   ./${EPIC_FILENAME} --skipeula --ssl-cert /home/centos/${CTRL_PUB_DNS}/cert.pem --ssl-priv-key /home/centos/${CTRL_PUB_DNS}/key.pem

   # install application workbench
   sudo yum install -y epel-release
   sudo yum install -y python-pip
   sudo pip install --upgrade pip
   sudo pip install --upgrade setuptools
   sudo pip install --upgrade bdworkbench

   touch /home/centos/bd_installed
ENDSSH

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat ~/${CTRL_PUB_DNS}/cert.pem" > generated/cert.pem
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat ~/${CTRL_PUB_DNS}/key.pem" > generated/key.pem

###############################################################################
# Manually configure Controller with Workers and Gateway
###############################################################################

# retrive controller ssh private key and save it locally
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" centos@${CTRL_PUB_IP} 'cat ~/.ssh/id_rsa' > generated/controller.prv_key

cat <<EOF>"$LOG_FILE"


*********************************************************
*      BlueData installation completed successfully     *
*********************************************************

SSH Private key has been downloaded to:
"${PROJECT_DIR}/generated/controller.prv_key"

** PLEASE KEEP IT SECURE **

INSTRUCTIONS for completing the BlueData installation ...

0. In your browser, navigate to the Controller URL: https://${CTRL_PUB_IP}"
1. At the setup screen, click 'Submit'
2. At the login screen, use 'admin/admin123'
3. Naviate to Settings -> License:
   1. Request a license from your BlueData sales engineer contact
   2. Upload the license
4. Navigate to Installation tab:

   1. Add workers private ips "$(echo ${WRKR_PRV_IPS[@]} | sed -e 's/ /,/g')"
   2. Add gateway private ip "${GATW_PRV_IP}" and public dns "${GATW_PUB_DNS}"
   3. Upload "${PROJECT_DIR}/generated/controller.prv_key"
   4. Click Add hosts (enter site lock down when prompted)

   # After a few minutes, you should see Gateway 'Installed' and Workers 'Bundle completed'

   5. Select each Worker
   6. Click 'Install'
   7. Wait a few minutes

** These instructions have been saved to "${LOG_FILE}" **


EOF
cat "$LOG_FILE"

