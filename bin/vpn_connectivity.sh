#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

source "./scripts/variables.sh"
source "./scripts/functions.sh"

RED='\033[0;31m'
NC='\033[0m' # No Color

echo
echo -e "${RED}Attempting to ping the controller private IP${NC}"
ping -c 5 $CTRL_PRV_IP

echo
echo -e "${RED}Attempting to ping the controller private DNS${NC}"
ping -c 5 $CTRL_PRV_DNS

command -v scutil >/dev/null 2>&1 && { 
    echo
    echo -e "${RED}OS X Nameservers${NC}"
    scutil --dns | grep 'nameserver\[[0-9]*\]'
}

echo

