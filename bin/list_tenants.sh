#!/bin/bash 

set -e
set -o pipefail
set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh


# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

hpecp tenant list