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