#!/bin/bash

HIDE_WARNINGS=1

source "./scripts/variables.sh"

./generated/ssh_mapr_cluster_1_host_0.sh <<EOF

   sudo kill -TERM \$(ps -eaf | grep -i dashboard | awk '{ print \$2 }')

   set -e
   sudo service mapr-posix-client-basic restart

   sudo -u mapr bash <<EOF2
      set -e
      echo mapr | maprlogin password -user mapr

      cd /home/mapr/microservices-dashboard
      ./runDashboard.sh hq > /tmp/dashboard_hq.nohup &

      tail -f /tmp/dashboard_hq.nohup
EOF2
EOF
