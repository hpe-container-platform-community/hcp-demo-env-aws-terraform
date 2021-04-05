#!/bin/bash

HIDE_WARNINGS=${HIDE_WARNINGS:-0}

source "./scripts/variables.sh"
echo 
if [[ $RDP_PUB_IP == "" && $HIDE_WARNINGS == 0 ]]; then
  echo "WARNING: Unable to display RDP credentials because RDP_PUB_IP could not be retrieved - is the instance running?"
  exit
fi
echo ================================= RDP Credentials  =====================================
echo 
if [[ "$CREATE_EIP_RDP_LINUX_SERVER" == "False" ]]; then
echo Note: The RDP IP addresses listed below change each time the RDP instance is restarted.
else
echo Note: The RDP IP addresses listed below are provided by an EIP and are static.
fi
echo
echo Host IP:   "$RDP_PUB_IP"
echo Web Url:   "https://$RDP_PUB_IP (Chrome is recommended)"
echo RDP URL:   "rdp://full%20address=s:$RDP_PUB_IP:3389&username=s:ubuntu"
echo Username:  "ubuntu"
echo Password:  "$RDP_INSTANCE_ID"
echo 
echo ========================================================================================
echo
