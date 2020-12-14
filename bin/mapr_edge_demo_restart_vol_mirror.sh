#!/bin/bash

HIDE_WARNINGS=1

source "./scripts/variables.sh"

./generated/ssh_mapr_cluster_2_host_0.sh <<EOF
   sudo -u mapr bash <<BASH_EOF
   set -x
   maprcli volume mirror stop -name files-missionX
   maprcli volume mirror start -name files-missionX
BASH_EOF
EOF
