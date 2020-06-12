#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

source "./scripts/variables.sh"
source "./scripts/functions.sh"

RED='\033[0;31m'
NC='\033[0m' # No Color

echo
echo -e "${RED}Attempting to ping the controller public IP${NC}"
ping -c 5 $CTRL_PUB_IP

echo

