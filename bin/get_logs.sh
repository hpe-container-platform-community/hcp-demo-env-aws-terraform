#!/bin/bash

source "./scripts/variables.sh"


THE_DATE=$(date +"%Y-%m-%dT%H-%M-%S%z")
   
./bin/ssh_controller.sh sudo tar czf - /var/log/bluedata/ > ${THE_DATE}-controller-logs.tar.gz
       
for i in "${!WRKR_PUB_IPS[@]}"; do
  ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@${WRKR_PUB_IPS[$i]} sudo tar czf - /var/log/bluedata/ > ${THE_DATE}-worker-${i}-${WRKR_PRV_IPS[$i]}-logs.tar.gz
done
