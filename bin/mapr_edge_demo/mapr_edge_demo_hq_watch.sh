#!/bin/bash

HIDE_WARNINGS=1

source "./scripts/variables.sh"

./generated/ssh_mapr_cluster_1_host_0.sh -t \
   "bash -c 'watch ls -lr /mapr/dc1.enterprise.org/apps/pipeline/data/files-missionX'"