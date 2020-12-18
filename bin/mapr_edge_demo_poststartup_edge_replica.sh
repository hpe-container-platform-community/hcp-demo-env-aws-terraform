#!/bin/bash

export HIDE_WARNINGS=1

source "./scripts/variables.sh"


./generated/ssh_mapr_cluster_1_host_0.sh sudo -u mapr bash <<EOF

   echo mapr | maprlogin password -user mapr
   maprlogin authtest

   echo mapr | maprlogin password -user mapr -cluster dc1.enterprise.org
   maprlogin authtest -cluster dc1.enterprise.org

   . /home/mapr/microservices-dashboard/scripts/hq/create-edge-replica.sh
EOF