#!/bin/bash 

set -e
set -o pipefail

# See here for more information: https://github.com/antonbabenko/terraform-cost-estimation

echo -n "Checking jq version ... "
if ! command -v jq >/dev/null 2>&1 || ! jq --version | grep 'jq-1.6.*'; then
   echo "I need jq 1.6+.  Aborting."
   echo "Linux: https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
   exit 1
fi

curl -sLO https://raw.githubusercontent.com/antonbabenko/terraform-cost-estimation/master/terraform.jq


STATE=$(terraform state pull |  jq -cf terraform.jq)
echo
echo "Sending data to https://cost.modules.tf/"
echo "DATA: ${STATE}"
echo
echo ${STATE} | curl -s -X POST -H "Content-Type: application/json" -d @- https://cost.modules.tf/
echo


