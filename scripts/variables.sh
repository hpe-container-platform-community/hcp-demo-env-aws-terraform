#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
OUTPUT_JSON=$(cat "${SCRIPT_DIR}/../generated/output.json")

###############################################################################
# Set variables from terraform output
###############################################################################

# Ensure python is able to parse the OUTPUT_JSON file
python3 - <<____HERE
import json,sys,subprocess

try:
   with open('${SCRIPT_DIR}/../generated/output.json') as f:
      json.load(f)
except: 
   print(80 * "*")
   print("ERROR: Can't parse: '${SCRIPT_DIR}/../generated/output.json'")
   print(80 * "*")
   sys.exit(1)
____HERE

###############################################################################
# Set variables from terraform output
###############################################################################

PROJECT_DIR=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["project_dir"]["value"])')
#echo PROJECT_DIR="${PROJECT_DIR}"
[ "$PROJECT_DIR" ] || ( echo "ERROR: PROJECT_DIR is empty" && exit 1 )

LOG_FILE="${PROJECT_DIR}"/generated/bluedata_install_output.txt
# [[ -f "$LOG_FILE" ]] && mv -f "$LOG_FILE" "${LOG_FILE}".old

CLIENT_CIDR_BLOCK=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["client_cidr_block"]["value"])')
[ "$CLIENT_CIDR_BLOCK" ] || ( echo "ERROR: CLIENT_CIDR_BLOCK is empty" && exit 1 )

REGION=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["aws_region"]["value"])')
[ "$REGION" ] || ( echo "ERROR: REGION is empty" && exit 1 )

LOCAL_SSH_PUB_KEY_PATH=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ssh_pub_key_path"]["value"])')
LOCAL_SSH_PRV_KEY_PATH=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ssh_prv_key_path"]["value"])')

[ "$LOCAL_SSH_PUB_KEY_PATH" ] || ( echo "ERROR: LOCAL_SSH_PUB_KEY_PATH is empty" && exit 1 )
[ "$LOCAL_SSH_PRV_KEY_PATH" ] || ( echo "ERROR: LOCAL_SSH_PRV_KEY_PATH is empty" && exit 1 )

#echo LOCAL_SSH_PUB_KEY_PATH=${LOCAL_SSH_PUB_KEY_PATH}
#echo LOCAL_SSH_PRV_KEY_PATH=${LOCAL_SSH_PRV_KEY_PATH}

CREATE_EIP_CONTROLLER=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["create_eip_controller"]["value"])')
CREATE_EIP_GATEWAY=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["create_eip_gateway"]["value"])')

[ "$CREATE_EIP_CONTROLLER" ] || ( echo "ERROR: CREATE_EIP_CONTROLLER is empty" && exit 1 )
[ "$CREATE_EIP_GATEWAY" ]    || ( echo "ERROR: CREATE_EIP_GATEWAY is empty" && exit 1 )

#echo CREATE_EIP_CONTROLLER=${CREATE_EIP_CONTROLLER}
#echo CREATE_EIP_GATEWAY=${CREATE_EIP_GATEWAY}

CA_KEY="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ca_key"]["value"])')"
CA_CERT="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ca_cert"]["value"])')"

[ "$CA_KEY" ] || ( echo "ERROR: CA_KEY is empty" && exit 1 )
[ "$CA_CERT" ] || ( echo "ERROR: CA_CERT is empty" && exit 1 )

EPIC_DL_URL="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epic_dl_url"]["value"])')"
EPIC_FILENAME="$(echo ${EPIC_DL_URL##*/} | cut -d? -f1)"
EPIC_DL_URL_NEEDS_PRESIGN="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epid_dl_url_needs_presign"]["value"])')"
EPIC_DL_URL_PRESIGN_OPTIONS="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epic_dl_url_presign_options"]["value"])')"

#echo EPIC_DL_URL=$EPIC_DL_URL
#echo EPIC_FILENAME=$EPIC_FILENAME
#echo EPIC_DL_URL_NEEDS_PRESIGN=$EPIC_DL_URL_NEEDS_PRESIGN

[ "$EPIC_DL_URL" ] || ( echo "ERROR: EPIC_DL_URL is empty" && exit 1 )
[ "$EPIC_FILENAME" ] || ( echo "ERROR: EPIC_FILENAME is empty" && exit 1 )
[ "$EPIC_DL_URL_NEEDS_PRESIGN" ] || ( echo "ERROR: EPIC_DL_URL_NEEDS_PRESIGN is empty" && exit 1 )
# EPIC_DL_URL_PRESIGN_OPTIONS can be empty


SELINUX_DISABLED="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["selinux_disabled"]["value"])')"
#echo SELINUX_DISABLED=$SELINUX_DISABLED
[ "$SELINUX_DISABLED" ] || ( echo "ERROR: SELINUX_DISABLED is empty" && exit 1 )

CTRL_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_private_ip"]["value"])') 
CTRL_PUB_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_public_ip"]["value"])') 
CTRL_PRV_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_private_dns"]["value"])') 
CTRL_PUB_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_public_dns"]["value"])') 

CTRL_PUB_HOST=$(echo $CTRL_PUB_DNS | cut -d"." -f1)
CTRL_PRV_HOST=$(echo $CTRL_PRV_DNS | cut -d"." -f1)

#echo CTRL_PRV_IP=$CTRL_PRV_IP
#echo CTRL_PUB_IP=$CTRL_PUB_IP
#echo CTRL_PRV_DNS=$CTRL_PRV_DNS
#echo CTRL_PUB_DNS=$CTRL_PUB_DNS
#echo CTRL_PUB_HOST=$CTRL_PUB_HOST
#echo CTRL_PRV_HOST=$CTRL_PRV_HOST

### TODO: refactor this checks below to a method

[ "$CTRL_PRV_IP" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PRV_IP is empty - is the EC2 instance running?"
   echo
   echo "       You can check instance status with: ./generated/cli_running_ec2_instances.sh"
   echo "       You can start instances with: ./generated/cli_start_ec2_instances.sh"
   echo "***********************************************************************************"
   exit 1 
}

[ "$CTRL_PUB_IP" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PUB_IP is empty - is the EC2 instance running?"
   echo
   echo "       You can check instance status with: ./generated/cli_running_ec2_instances.sh"
   echo "       You can start instances with: ./generated/cli_start_ec2_instances.sh"
   echo "***********************************************************************************"
   exit 1 
}

[ "$CTRL_PRV_DNS" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PRV_DNS is empty - is the EC2 instance running?"
   echo
   echo "       You can check instance status with: ./generated/cli_running_ec2_instances.sh"
   echo "       You can start instances with: ./generated/cli_start_ec2_instances.sh"
   echo "***********************************************************************************"
   exit 1 
}

[ "$CTRL_PUB_DNS" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PUB_DNS is empty - is the EC2 instance running?"
   echo
   echo "       You can check instance status with: ./generated/cli_running_ec2_instances.sh"
   echo "       You can start instances with: ./generated/cli_start_ec2_instances.sh"
   echo "***********************************************************************************"
   exit 1 
}

[ "$CTRL_PUB_HOST" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PUB_HOST is empty - is the EC2 instance running?"
   echo
   echo "       You can check instance status with: ./generated/cli_running_ec2_instances.sh"
   echo "       You can start instances with: ./generated/cli_start_ec2_instances.sh"
   echo "***********************************************************************************"
   exit 1 
}

[ "$CTRL_PRV_HOST" ] || {
   echo "***********************************************************************************"
   echo "ERROR: CTRL_PRV_HOST is empty - is the EC2 instance running?"
   echo
   echo "       You can check instance status with: ./generated/cli_running_ec2_instances.sh"
   echo "       You can start instances with: ./generated/cli_start_ec2_instances.sh"
   echo "***********************************************************************************"
   exit 1 
}

GATW_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_private_ip"]["value"])') 
GATW_PUB_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_public_ip"]["value"])') 
GATW_PRV_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_private_dns"]["value"])') 
GATW_PUB_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_public_dns"]["value"])') 
GATW_PUB_HOST=$(echo $GATW_PUB_DNS | cut -d"." -f1)
GATW_PRV_HOST=$(echo $GATW_PRV_DNS | cut -d"." -f1)

#echo GATW_PRV_IP=$GATW_PRV_IP
#echo GATW_PUB_IP=$GATW_PUB_IP
#echo GATW_PRV_DNS=$GATW_PRV_DNS
#echo GATW_PUB_DNS=$GATW_PUB_DNS
#echo GATW_PUB_HOST=$GATW_PUB_HOST
#echo GATW_PRV_HOST=$GATW_PRV_HOST

[ "$GATW_PRV_IP" ] || ( echo "ERROR: GATW_PRV_IP is empty - is the instance running?" && exit 1 )
[ "$GATW_PUB_IP" ] || ( echo "ERROR: GATW_PUB_IP is empty - is the instance running?" && exit 1 )
[ "$GATW_PRV_DNS" ] || ( echo "ERROR: GATW_PRV_DNS is empty - is the instance running?" && exit 1 )
[ "$GATW_PUB_DNS" ] || ( echo "ERROR: GATW_PUB_DNS is empty - is the instance running?" && exit 1 )
[ "$GATW_PUB_HOST" ] || ( echo "ERROR: GATW_PUB_HOST is empty - is the instance running?" && exit 1 )
[ "$GATW_PRV_HOST" ] || ( echo "ERROR: GATW_PRV_HOST is empty - is the instance running?" && exit 1 )

WRKR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_private_ip"]["value"][0], sep=" ")') 
WRKR_PUB_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_public_ip"]["value"][0], sep=" ")') 

[ "$WRKR_PRV_IPS" ] || ( echo "ERROR: WRKR_PRV_IPS is empty - is the instance running?" && exit 1 )
[ "$WRKR_PUB_IPS" ] || ( echo "ERROR: WRKR_PUB_IPS is empty - is the instance running?" && exit 1 )

read -r -a WRKR_PRV_IPS <<< "$WRKR_PRV_IPS"
read -r -a WRKR_PUB_IPS <<< "$WRKR_PUB_IPS"

#echo WRKR_PRV_IPS=${WRKR_PRV_IPS[@]}
#echo WRKR_PUB_IPS=${WRKR_PUB_IPS[@]}


AD_SERVER_ENABLED=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ad_server_enabled"]["value"])')

if [[ "$AD_SERVER_ENABLED" == "True" ]]; then
   AD_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ad_server_private_ip"]["value"])') 
   AD_PUB_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ad_server_public_ip"]["value"])') 
fi

RDP_SERVER_ENABLED=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_enabled"]["value"])')
RDP_SERVER_OPERATING_SYSTEM=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_operating_system"]["value"])')
CREATE_EIP_RDP_LINUX_SERVER=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["create_eip_rdp_linux_server"]["value"])')

if [[ "$RDP_SERVER_ENABLED" == "True" ]]; then
   RDP_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_private_ip"]["value"])') 
   RDP_PUB_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_public_ip"]["value"])') 
   RDP_INSTANCE_ID=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_instance_id"]["value"])') 

   if [[ "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" && ! "$RDP_PUB_IP"  ]]; then
      echo "***********************************************************************************"
      echo "ERROR: RDP_PUB_IP is empty - is the EC2 instance running?"
      echo
      echo "       You can check instance status with: ./generated/cli_running_ec2_instances.sh"
      echo "       You can start instances with: ./generated/cli_start_ec2_instances.sh"
      echo "***********************************************************************************"
      exit 1 
   fi
fi