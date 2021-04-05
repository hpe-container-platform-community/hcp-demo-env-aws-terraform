#!/bin/bash
source "./scripts/variables.sh"
ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" ubuntu@$RDP_PUB_IP "$@"    
