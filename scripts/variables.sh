#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

# disable '-x' because it is too verbose for this script
# and is not useful for for this script
if [[ $- == *x* ]]; then
  was_x_set=1
else
  was_x_set=0
fi
set +x

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
   print(80 * '*')
   print("ERROR: Can't parse: '${SCRIPT_DIR}/../generated/output.json'")
   print(80 * '*')
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

VPC_CIDR_BLOCK=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["vpc_cidr_block"]["value"])')
[ "$VPC_CIDR_BLOCK" ] || ( echo "ERROR: VPC_CIDR_BLOCK is empty" && exit 1 )

USER_TAG=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["user"]["value"])')
[ "$USER_TAG" ] || ( echo "ERROR: USER_TAG is empty" && exit 1 )

PROFILE=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["aws_profile"]["value"])')
[ "$PROFILE" ] || ( echo "ERROR: PROFILE is empty" && exit 1 )

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

INSTALL_WITH_SSL="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["install_with_ssl"]["value"])')"

CA_KEY="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ca_key"]["value"])')"
CA_CERT="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ca_cert"]["value"])')"

[ "$CA_KEY" ] || ( echo "ERROR: CA_KEY is empty" && exit 1 )
[ "$CA_CERT" ] || ( echo "ERROR: CA_CERT is empty" && exit 1 )

EPIC_DL_URL="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epic_dl_url"]["value"])')"
EPIC_FILENAME="$(echo ${EPIC_DL_URL##*/} | cut -d? -f1)"
EPIC_DL_URL_NEEDS_PRESIGN="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epid_dl_url_needs_presign"]["value"])')"
EPIC_DL_URL_PRESIGN_OPTIONS="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epic_dl_url_presign_options"]["value"])')"
EPIC_OPTIONS="$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["epic_options"]["value"])')"

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

CTRL_INSTANCE_ID=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_instance_id"]["value"])') 

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

IP_WARNING=()

[ "$CTRL_PRV_IP" ] || {
   IP_WARNING+=("CTRL_PRV_IP")
}

[ "$CTRL_PUB_IP" ] || {
   IP_WARNING+=("CTRL_PUB_IP")
}

# [ "$CTRL_PRV_DNS" ] || {
#    IP_WARNING+=("CTRL_PRV_DNS")
# }

# [ "$CTRL_PUB_DNS" ] || {
#    IP_WARNING+=("CTRL_PUB_DNS")
# }

# [ "$CTRL_PUB_HOST" ] || {
#    IP_WARNING+=("CTRL_PUB_HOST")
# }

# [ "$CTRL_PRV_HOST" ] || {
#    IP_WARNING+=("CTRL_PRV_HOST")
# }

GATW_INSTANCE_ID=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gateway_instance_id"]["value"])') 

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

[ "$GATW_PRV_IP" ] || IP_WARNING+=("GATW_PRV_IP")
[ "$GATW_PUB_IP" ] || IP_WARNING+=("GATW_PUB_IP")
# [ "$GATW_PRV_DNS" ] || IP_WARNING+=("GATW_PRV_DNS")
# [ "$GATW_PUB_DNS" ] || IP_WARNING+=("GATW_PUB_DNS")
# [ "$GATW_PUB_HOST" ] || IP_WARNING+=("GATW_PUB_HOST")
# [ "$GATW_PRV_HOST" ] || IP_WARNING+=("GATW_PRV_HOST")

#### WORKERS

WORKER_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["worker_count"]["value"][0], sep=" ")') 

if [[ "$WORKER_COUNT" != "0" ]]; then
   WRKR_INSTANCE_IDS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_instance_id"]["value"][0], sep=" ")') 
   WRKR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_private_ip"]["value"][0], sep=" ")') 
   WRKR_PUB_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_public_ip"]["value"][0], sep=" ")') 

   read -r -a WRKR_PRV_IPS <<< "$WRKR_PRV_IPS"
   read -r -a WRKR_PUB_IPS <<< "$WRKR_PUB_IPS"
else
   WRKR_INSTANCE_IDS=""
   WRKR_PRV_IPS=()
   WRKR_PUB_IPS=()
fi

#### GPU WORKERS

GPU_WORKER_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gpu_worker_count"]["value"][0], sep=" ")') 

if [[ "$GPU_WORKER_COUNT" != "0" ]]; then
   WRKR_GPU_INSTANCE_IDS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_gpu_instance_id"]["value"][0], sep=" ")') 
   WRKR_GPU_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_gpu_private_ip"]["value"][0], sep=" ")') 
   WRKR_GPU_PUB_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_gpu_public_ip"]["value"][0], sep=" ")') 

   read -r -a WRKR_GPU_PRV_IPS <<< "$WRKR_GPU_PRV_IPS"
   read -r -a WRKR_GPU_PUB_IPS <<< "$WRKR_GPU_PUB_IPS"
else
   WRKR_GPU_INSTANCE_IDS=""
   WRKR_GPU_PRV_IPS=()
   WRKR_GPU_PUB_IPS=()
fi

#### MAPR CLUSTER 1

MAPR_CLUSTER1_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["mapr_cluster_1_count"]["value"][0], sep=" ")') 
if [[ "$MAPR_CLUSTER1_COUNT" != "0" ]]; then
   MAPR_CLUSTER1_NAME=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["mapr_cluster_1_name"]["value"][0], sep=" ")') 
   MAPR_CLUSTER1_HOSTS_INSTANCE_IDS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["mapr_cluster_1_hosts_instance_id"]["value"][0], sep=" ")') 
   MAPR_CLUSTER1_HOSTS_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["mapr_cluster_1_hosts_private_ip"]["value"][0], sep=" ")') 
   MAPR_CLUSTER1_HOSTS_PUB_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["mapr_cluster_1_hosts_public_ip"]["value"][0], sep=" ")') 

   read -r -a MAPR_CLUSTER1_HOSTS_PRV_IPS <<< "$MAPR_CLUSTER1_HOSTS_PRV_IPS"
   read -r -a MAPR_CLUSTER1_HOSTS_PUB_IPS <<< "$MAPR_CLUSTER1_HOSTS_PUB_IPS"
else
   MAPR_CLUSTER1_NAME=""
   MAPR_CLUSTER1_HOSTS_INSTANCE_IDS=""
   MAPR_CLUSTER1_HOSTS_PRV_IPS=()
   MAPR_CLUSTER1_HOSTS_PUB_IPS=()
fi


MAPR_CLUSTER2_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["mapr_cluster_2_count"]["value"][0], sep=" ")') 
if [[ "$MAPR_CLUSTER2_COUNT" != "0" ]]; then
   MAPR_CLUSTER2_NAME=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["mapr_cluster_2_name"]["value"][0], sep=" ")') 
   MAPR_CLUSTER2_HOSTS_INSTANCE_IDS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["mapr_cluster_2_hosts_instance_id"]["value"][0], sep=" ")') 
   MAPR_CLUSTER2_HOSTS_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["mapr_cluster_2_hosts_private_ip"]["value"][0], sep=" ")') 
   MAPR_CLUSTER2_HOSTS_PUB_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["mapr_cluster_2_hosts_public_ip"]["value"][0], sep=" ")') 

   read -r -a MAPR_CLUSTER2_HOSTS_PRV_IPS <<< "$MAPR_CLUSTER2_HOSTS_PRV_IPS"
   read -r -a MAPR_CLUSTER2_HOSTS_PUB_IPS <<< "$MAPR_CLUSTER2_HOSTS_PUB_IPS"
else
   MAPR_CLUSTER2_NAME=""
   MAPR_CLUSTER2_HOSTS_INSTANCE_IDS=""
   MAPR_CLUSTER2_HOSTS_PRV_IPS=()
   MAPR_CLUSTER2_HOSTS_PUB_IPS=()
fi

AD_SERVER_ENABLED=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ad_server_enabled"]["value"])')

if [[ "$AD_SERVER_ENABLED" == "True" ]]; then
   AD_INSTANCE_ID=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ad_server_instance_id"]["value"])') 
   AD_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ad_server_private_ip"]["value"])') 
   AD_PUB_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ad_server_public_ip"]["value"])') 
else
   AD_INSTANCE_ID=""
fi

NFS_SERVER_ENABLED=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["nfs_server_enabled"]["value"])')

if [[ "$NFS_SERVER_ENABLED" == "True" ]]; then
   NFS_INSTANCE_ID=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["nfs_server_instance_id"]["value"])') 
else
   NFS_INSTANCE_ID=""
fi

RDP_SERVER_ENABLED=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_enabled"]["value"])')
RDP_SERVER_OPERATING_SYSTEM=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_operating_system"]["value"])')
CREATE_EIP_RDP_LINUX_SERVER=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["create_eip_rdp_linux_server"]["value"])')

if [[ "$RDP_SERVER_ENABLED" == "True" ]]; then
   RDP_INSTANCE_ID=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_instance_id"]["value"])') 
   RDP_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_private_ip"]["value"])') 
   RDP_PUB_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_public_ip"]["value"])') 
   RDP_INSTANCE_ID=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["rdp_server_instance_id"]["value"])') 

   if [[ "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" && ! "$RDP_PUB_IP"  ]]; then
      IP_WARNING+=("RDP_PUB_IP")
   fi
else
   RDP_INSTANCE_ID=""
fi

CREATE_EKS_CLUSTER=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["create_eks_cluster"]["value"])')


if [[ $was_x_set == 1 ]]; then
   set -x
else
   set +x
fi 

# TODO: complete this

ALL_CP_INSTANCE_IDS="${CTRL_INSTANCE_ID} ${GATW_INSTANCE_ID} ${WRKR_INSTANCE_IDS} ${WRKR_GPU_INSTANCE_IDS} ${NFS_INSTANCE_ID} ${AD_INSTANCE_ID} ${RDP_INSTANCE_ID}"

ALL_MAPR_INSTANCE_IDS="${MAPR_CLUSTER1_HOSTS_INSTANCE_IDS} ${MAPR_CLUSTER2_HOSTS_INSTANCE_IDS}"

ALL_INSTANCE_IDS="${ALL_CP_INSTANCE_IDS} ${MAPR_CLUSTER1_HOSTS_INSTANCE_IDS} ${MAPR_CLUSTER2_HOSTS_INSTANCE_IDS}"

if [[ ${#IP_WARNING[@]} != 0 ]]; then
   tput setaf 3
   echo "WARNING: ${IP_WARNING[@]} could not be retrieved -> is the instance(s) running?"
   tput sgr0
fi

