#!/bin/bash

export HIDE_WARNINGS=1

source "./scripts/variables.sh"
   
./generated/ssh_mapr_cluster_2_host_0.sh <<EOF
   sudo -u mapr bash <<BASH_EOF
      set -x
      maprcli config save -values "{\"mfs.enable.audit.as.stream\":\"1\"}"
      maprcli audit data -enabled true -retention 1
      maprcli volume audit -name mapr.apps -enabled true -dataauditops +create,+delete,+tablecreate,-setattr,-chown,-chperm,-chgrp,-getxattr,-listxattr,-setxattr,-removexattr,-read,-write,-mkdir,-readdir,-rmdir,-createsym,-lookup,-rename,-createdev,-truncate,-tablecfcreate,-tablecfdelete,-tablecfmodify,-tablecfScan,-tableget,-tableput,-tablescan,-tableinfo,-tablemodify,-getperm,-getpathforfid,-hardlink
      maprcli volume info -name mapr.apps -json
      hadoop mfs -setaudit on /apps/pipeline/data
      hadoop mfs -ls /apps/pipeline
BASH_EOF
EOF
