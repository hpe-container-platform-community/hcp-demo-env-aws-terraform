#!/bin/bash


set -e # abort on error
set -u # abort on undefined variable

source "scripts/variables.sh"

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -tt -T centos@${CTRL_PUB_IP} <<-SSH_EOF
   set -eu
   bdmapr maprcli acl edit -type  cluster -user ad_admin1:fc
SSH_EOF
