#!/bin/bash

set -e

source ./scripts/variables.sh
source ./scripts/functions.sh

pip3 install --quiet --upgrade --user hpecp

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

echo "Deleting and creating lock"
hpecp lock delete-all
hpecp lock create "Set CPU allocation ratio"

hpecp httpclient put /api/v1/install/?install_reconfig --json-file <(echo '{"cpu_allocation_ratio": 2}')

echo "Request successful - exiting site lock-down"

hpecp lock delete-all