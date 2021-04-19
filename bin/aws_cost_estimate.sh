#!/bin/bash 

set -e
set -o pipefail


echo -n "Checking jq version ... "
if ! command -v jq >/dev/null 2>&1 || ! jq --version | grep 'jq-1.6.*'; then
   echo "I need jq 1.6+.  Aborting."
   echo "Linux: https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
   exit 1
fi


read -r -p "This script will send you state data to https://cost.modules.tf - Are you sure? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        true
        ;;
    *)
        exit 1
        ;;
esac

echo
terraform state pull |  jq -cf terraform.jq | curl -s -X POST -H "Content-Type: application/json" -d @- https://cost.modules.tf/
echo


