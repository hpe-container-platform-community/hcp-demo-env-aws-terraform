#!/bin/bash

export HIDE_WARNINGS=1

source "./scripts/variables.sh"
source "./scripts/functions.sh"

################################################################################
print_header "dbshell docs - https://docs.datafabric.hpe.com/62/ReferenceGuide/mapr_dbshell.html"
echo
echo "Running 'find /apps/pipeline/data/imagesTable --limit 1 --pretty'"
print_term_width '-'
################################################################################

./generated/ssh_mapr_cluster_1_host_0.sh sudo -u mapr bash <<EOF
   exec 2> /dev/null
   mapr dbshell --cmdfile <(echo 'find /apps/pipeline/data/imagesTable --limit 1 --pretty') 
EOF