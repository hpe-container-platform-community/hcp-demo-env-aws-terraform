#!/bin/bash 

set -e
set -o pipefail

# See here for more information: https://github.com/antonbabenko/terraform-cost-estimation

if [[ "$EUID" != "0" ]]; then
  echo "This script must be run as root - e.g." 
  echo "sudo $0"
  exit 1
fi




echo -n "Checking jq version ... "
if ! command -v jq >/dev/null 2>&1 || ! jq --version | grep 'jq-1.6.*'; then

   if [[ -z $C9_PROJECT ]]; then
      rm -f jq-linux64
      wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
      mv -f jq-linux64 /usr/local/bin/jq
      chmod +x /usr/local/bin/jq
   else
      echo "I need jq 1.6+.  Aborting."
      echo "Linux: https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
      exit 1
   fi
fi

curl -sLO https://raw.githubusercontent.com/antonbabenko/terraform-cost-estimation/master/terraform.jq


STATE=$(terraform state pull |  /usr/local/bin/jq -cf terraform.jq)
echo
echo "Sending data to https://cost.modules.tf/"
echo "DATA: ${STATE}"
echo
echo ${STATE} | curl -s -X POST -H "Content-Type: application/json" -d @- https://cost.modules.tf/
echo


