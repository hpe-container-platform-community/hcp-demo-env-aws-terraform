#!/bin/bash

source ./scripts/functions.sh

RED='\033[0;31m'
NC='\033[0m' # No Color

echo
echo -e "${RED}EPIC Catalog Images : Installed${NC}"
hpecp catalog list --query "[?state=='installed'] | [*].[_links.self.href,label.name,state]" | perl -pe 's/\], \[/,\n/g'

echo
echo -e "${RED}EPIC Catalog Images : NOT Installed${NC}"
hpecp catalog list --query "[?state!='installed'] | [*].[_links.self.href,label.name,state]" | perl -pe 's/\], \[/,\n/g'
