#!/bin/bash
source "./scripts/variables.sh"
ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@$CTRL_PUB_IP "$@"
