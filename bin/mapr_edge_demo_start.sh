#!/bin/bash

HIDE_WARNINGS=1

set -eu

source "./scripts/variables.sh"
source "./scripts/functions.sh"


################################################################################ 
print_header "Shutting down any running dashboard instances"
################################################################################ 

./generated/ssh_mapr_cluster_1_host_0.sh <<EOF
   set -x
   # ignore error from kill
   sudo kill -TERM \$(ps -eaf | grep -i dashboard | awk '{ print \$2 }') || true 
EOF


./generated/ssh_mapr_cluster_2_host_0.sh <<EOF
   set -x
   # ignore error from kill
   sudo kill -TERM \$(ps -eaf | grep -i dashboard | awk '{ print \$2 }') || true
EOF


################################################################################ 
print_header "Ensuring /opt/mapr/conf/mapruserticket contains DC1 and EDGE1"
################################################################################ 

./bin/mapr_edge_demo_mapruserticket_setup.sh

################################################################################ 
print_header "Starting HQ Instance"
################################################################################ 

./generated/ssh_mapr_cluster_1_host_0.sh <<EOF
   set -ex
   sudo service mapr-posix-client-basic restart

   sudo -u mapr bash <<EOF2
      set -ex
      echo mapr | maprlogin password -user mapr
      maprlogin authtest

      echo mapr | maprlogin password -user mapr -cluster edge1.enterprise.org
      maprlogin authtest -cluster edge1.enterprise.org

      cd /home/mapr/microservices-dashboard
      ./runDashboard.sh hq > /mapr/dc1.enterprise.org/tmp/dashboard_hq.nohup &
EOF2
EOF

################################################################################ 
print_header "Starting Edge Instance"
################################################################################ 

./generated/ssh_mapr_cluster_2_host_0.sh <<EOF
   set -ex
   sudo service mapr-posix-client-basic restart

   EDGE_HOSTNAME=\$(hostname -f)

   sudo -u mapr bash <<EOF2
      set -ex
      echo mapr | maprlogin password -user mapr
      maprlogin authtest

      echo mapr | maprlogin password -user mapr -cluster dc1.enterprise.org
      maprlogin authtest -cluster dc1.enterprise.org

      cd /home/mapr/microservices-dashboard

      # This requires the EDGE_HOSTNAME variable set
      export EDGE_HOSTNAME=\$EDGE_HOSTNAME
      echo EDGE_HOSTNAME=\$EDGE_HOSTNAME
      ./runDashboard.sh edge > /mapr/edge1.enterprise.org/tmp/dashboard_edge.nohup &
EOF2
EOF

################################################################################ 
print_header "Set stream replica, mirror, auditing"
################################################################################ 

./bin/mapr_edge_demo_poststartup.sh

################################################################################ 
print_header "Tailing dashboard startup log files"
################################################################################ 

./generated/ssh_mapr_cluster_2_host_0.sh <<EOF
   set -ex
   tail -f \
      /mapr/dc1.enterprise.org//tmp/dashboard_hq.nohup \
      /mapr/edge1.enterprise.org/tmp/dashboard_edge.nohup 
EOF