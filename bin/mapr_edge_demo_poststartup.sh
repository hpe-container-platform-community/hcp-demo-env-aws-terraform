#!/bin/bash

export HIDE_WARNINGS=1

source "./scripts/variables.sh"

DC_MAPR_USERTICKET="$(HIDE_WARNINGS=1 ./generated/ssh_mapr_cluster_1_host_0.sh 'sudo head -n1 /opt/mapr/conf/mapruserticket')"
EDGE_MAPR_USERTICKET="$(HIDE_WARNINGS=1 ./generated/ssh_mapr_cluster_2_host_0.sh 'sudo head -n1 /opt/mapr/conf/mapruserticket')"

# Ensure mapruserticket is the same on all nodes on the hq cluster and the edge cluster
for I in 0 1 2; do
   echo "$DC_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_1_host_$I.sh "sudo bash -c 'cat > /opt/mapr/conf/mapruserticket'"

   echo "$EDGE_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_2_host_$I.sh "sudo bash -c 'cat > /opt/mapr/conf/mapruserticket'"
done;

# Ensure all nodes in both clusters have maprusertickets for both hq and edge
for I in 0 1 2; do
   echo "$DC_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_2_host_$I.sh "sudo bash -c 'cat >> /opt/mapr/conf/mapruserticket'"
      
   echo "$EDGE_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_1_host_$I.sh "sudo bash -c 'cat >> /opt/mapr/conf/mapruserticket'"
done;

# verify maprusertickets
for i in 1 2; do   
  for j in 0 1 2; do    
    echo CLUSTER $i HOST $j;   
    ./generated/ssh_mapr_cluster_${i}_host_${j}.sh "sudo cat /opt/mapr/conf/mapruserticket"
  done;
done;

./generated/ssh_mapr_cluster_1_host_0.sh \
   "sudo -u mapr bash -c '. /home/mapr/microservices-dashboard/scripts/hq/create-edge-replica.sh'"
   
./generated/ssh_mapr_cluster_2_host_0.sh \
   "sudo -u mapr bash -c '. /home/mapr/microservices-dashboard/scripts/edge/createMirror.sh'"

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
