#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

source "./scripts/variables.sh"
source "./scripts/functions.sh"

################################################################################
print_header "Installing MAPR"
################################################################################

if [[ "$MAPR_CLUSTER1_COUNT" != "0" ]]; then
   (
      print_header "Installing MAPR Cluster 1"
      CLUSTER_ID=1
      ./scripts/mapr_install.sh ${CLUSTER_ID}
      ./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh ${CLUSTER_ID}
   ) &
fi

if [[ "$MAPR_CLUSTER2_COUNT" != "0" ]]; then
   (
      print_header "Installing MAPR Cluster 2"
      CLUSTER_ID=2
      ./scripts/mapr_install.sh ${CLUSTER_ID}
      ./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh ${CLUSTER_ID}
   ) &
fi

FAIL=0

for job in $(jobs -p); do
    wait $job || FAIL=1
done

if [ "$FAIL" != "0" ]; then
   echo "ERROR: failed to install MAPR"
   exit 1
fi

# Only setup cross-cluster security if you have two clusters!
if [[ "$MAPR_CLUSTER1_COUNT" == "0" ]] || [[ "$MAPR_CLUSTER2_COUNT" == "0" ]]; then
   print_header "Done!"
   exit 0
fi

################################################################################
print_header "Setting up Cross-Cluster Security"
################################################################################

DC_MAPR_USERTICKET="$(HIDE_WARNINGS=1 ./generated/ssh_mapr_cluster_1_host_0.sh 'sudo head -n1 /opt/mapr/conf/mapruserticket')"
EDGE_MAPR_USERTICKET="$(HIDE_WARNINGS=1 ./generated/ssh_mapr_cluster_2_host_0.sh 'sudo head -n1 /opt/mapr/conf/mapruserticket')"

for I in 0 1 2; do
   echo "$DC_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_1_host_$I.sh "sudo bash -c 'cat > /opt/mapr/conf/mapruserticket'"

   echo "$EDGE_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_2_host_$I.sh "sudo bash -c 'cat > /opt/mapr/conf/mapruserticket'"
done;

for I in 0 1 2; do
   echo "$DC_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_2_host_$I.sh "sudo bash -c 'cat >> /opt/mapr/conf/mapruserticket'"
      
   echo "$EDGE_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_1_host_$I.sh "sudo bash -c 'cat >> /opt/mapr/conf/mapruserticket'"
done;

for i in 1 2; do   
  for j in 0 1 2; do    
    echo CLUSTER $i HOST $j;   
    ./generated/ssh_mapr_cluster_${i}_host_${j}.sh "sudo cat /opt/mapr/conf/mapruserticket"
  done;
done;


printf $(terraform output -json mapr_cluster_1_hosts_private_ip_flat) | sed 's/"//' > localmaprhosts
printf $(terraform output -json mapr_cluster_2_hosts_private_ip_flat) | sed 's/"//' > remotemaprhosts

./generated/ssh_mapr_cluster_1_host_0.sh \
   "sudo -u mapr bash -c 'cat > /tmp/localmaprhosts && cat /tmp/localmaprhosts'" < localmaprhosts
   
./generated/ssh_mapr_cluster_1_host_0.sh \
   "sudo -u mapr bash -c 'cat > /tmp/remotemaprhosts && cat /tmp/remotemaprhosts'" < remotemaprhosts

./generated/ssh_mapr_cluster_1_host_0.sh "sudo apt-get -y install expect pssh"

./generated/ssh_mapr_cluster_1_host_0.sh "sudo -u mapr expect" <<EOF

   set remoteip [exec head -n1 /tmp/remotemaprhosts]
   
   spawn /opt/mapr/server/configure-crosscluster.sh create all \
         -localuser mapr -localhosts /tmp/localmaprhosts \
         -remoteuser mapr -remotehosts /tmp/remotemaprhosts \
         -remoteip \$remoteip

   expect "Enter password for mapr user (mapr) for local cluster:" { send "mapr\r" }
   expect "Enter password for mapr user (mapr) for remote cluster:" { send "mapr\r" }
   expect eof
EOF

################################################################################ 
print_header "Verify Cross-Cluster Security"
################################################################################ 

echo mapr | ./generated/ssh_mapr_cluster_1_host_0.sh \
   sudo -u mapr maprlogin password -cluster edge1.enterprise.org

echo mapr | ./generated/ssh_mapr_cluster_2_host_0.sh \
   sudo -u mapr maprlogin password -cluster dc1.enterprise.org

################################################################################ 
print_header "Done!"
################################################################################ 