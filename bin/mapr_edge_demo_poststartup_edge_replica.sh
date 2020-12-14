#!/bin/bash

export HIDE_WARNINGS=1

source "./scripts/variables.sh"

./generated/ssh_mapr_cluster_1_host_0.sh \
   "sudo -u mapr bash -c '. /home/mapr/microservices-dashboard/scripts/hq/create-edge-replica.sh'"
