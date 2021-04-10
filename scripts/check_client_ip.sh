#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/variables.sh"

CURR_CLIENT_CIDR_BLOCK="$(curl -s http://ipinfo.io/ip)/32"

if [[ "$CLIENT_CIDR_BLOCK" = "$CURR_CLIENT_CIDR_BLOCK" ]];
then
   echo "Your client IP address [${CLIENT_CIDR_BLOCK}] has not changed - no need to update AWS NACL or SG rules"
else
   echo "*********************************************************************************************************"
   echo "Your client IP adddress was previously [${CLIENT_CIDR_BLOCK}] and is now [${CURR_CLIENT_CIDR_BLOCK}]"
   echo "It appears to have changed since you last ran './bin/terraform_apply', so you should run the"
   echo "following command to update your environment with your new IP address:"
   echo
   echo "./bin/terraform_apply.sh"
   echo "*******************************************************************************************************"
   exit 1
fi