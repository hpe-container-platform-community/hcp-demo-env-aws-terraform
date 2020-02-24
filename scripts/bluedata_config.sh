#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

###############################################################################
# Set variables from terraform output
###############################################################################

LOCAL_SSH_PRV_KEY_PATH=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ssh_prv_key_path"]["value"])')
CTRL_PUB_IP=$(cat output.json | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["controller_public_ip"]["value"])') 

[ "$LOCAL_SSH_PRV_KEY_PATH" ] || ( echo "ERROR: LOCAL_SSH_PRV_KEY_PATH is empty" && exit 1 )
[ "$CTRL_PUB_IP" ] || ( echo "ERROR: CTRL_PUB_IP is empty" && exit 1 )

###############################################################################
# Configure Controller
###############################################################################

scp -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} initial_bluedata_config.py centos@${CTRL_PUB_IP}:~/initial_bluedata_config.py

ssh -o StrictHostKeyChecking=no -i ${LOCAL_SSH_PRV_KEY_PATH} -T centos@${CTRL_PUB_IP} << ENDSSH
   sudo pip install --quiet bs4
   ./initial_bluedata_config.py
ENDSSH

