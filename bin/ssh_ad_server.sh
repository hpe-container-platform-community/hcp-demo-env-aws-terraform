#!/bin/bash
source "./scripts/variables.sh"

if [[ "$AD_SERVER_ENABLED" == "True" ]]; then
   ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@$AD_PUB_IP "$@"
else
   echo "Aborting. AD Server has not been enabled"
fi
