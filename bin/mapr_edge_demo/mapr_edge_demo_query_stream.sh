#!/bin/bash

export HIDE_WARNINGS=1

source "./scripts/variables.sh"
source "./scripts/functions.sh"

################################################################################
print_header "streamanalyzer docs - https://docs.datafabric.hpe.com/62/ReferenceGuide/mapr_streamanalyzer.html"
echo
echo "Running 'mapr streamanalyzer -path /apps/pipeline/data/pipelineStream -printMessages'"
print_term_width '-'
################################################################################

./generated/ssh_mapr_cluster_1_host_0.sh sudo -u mapr bash <<EOF
   mapr streamanalyzer -path /apps/pipeline/data/pipelineStream -printMessages true

   mapr exportstream -src /apps/pipeline/data/pipelineStream -dst /tmp/pipelineStream
EOF

