#!/bin/bash

HIDE_WARNINGS=1

source "./scripts/variables.sh"
source "./scripts/functions.sh"


echo "Running 'maprcli service list'"
echo "See https://docs.datafabric.hpe.com/62/ReferenceGuide/service-list.html#servicelist__state"
echo

################################################################################ 
print_header "Host 0 service list"
################################################################################ 

./generated/ssh_mapr_cluster_1_host_0.sh sudo -u mapr bash <<EOF
   set -e

   echo mapr | maprlogin password -user mapr
   maprlogin authtest

   /opt/mapr/bin/maprcli service list
EOF

################################################################################ 
print_header "Host 1 service list"
################################################################################ 

./generated/ssh_mapr_cluster_1_host_1.sh sudo -u mapr bash <<EOF
   set -e

   echo mapr | maprlogin password -user mapr
   maprlogin authtest
   
   /opt/mapr/bin/maprcli service list
EOF

################################################################################ 
print_header "Host 2 service list"
################################################################################ 

./generated/ssh_mapr_cluster_1_host_2.sh sudo -u mapr bash <<EOF
   set -e

   echo mapr | maprlogin password -user mapr
   maprlogin authtest
   
   /opt/mapr/bin/maprcli service list
EOF

################################################################################ 
print_header "Done"
################################################################################ 

