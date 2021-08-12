#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
    exit
}

while :
do
   THE_DATE=$(date +"%Y-%m-%dT%H:%M:%S%z")
   ./bin/create_new_environment_from_scratch_with_picasso.sh > ${THE_DATE}-picasso.log 2>&1
   
   if hpecp k8scluster list | grep error
   then
        ./bin/ssh_controller.sh sudo tar czf - /var/log/bluedata/ > ${THE_DATE}-controller-logs.tar.gz
        
        source "./scripts/variables.sh"
       
        for i in "${!WRKR_PUB_IPS[@]}"; do
          ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@${WRKR_PUB_IPS[$i]} sudo tar czf - /var/log/bluedata/ > ${THE_DATE}-${WRKR_PUB_IPS[$i]}-logs.tar.gz
        done
    fi
    ./bin/terraform_destroy_accept.sh
done