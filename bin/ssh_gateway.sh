#!/bin/bash
source "./scripts/variables.sh"
ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@$GATW_PUB_IP "$@"
