#!/bin/bash

source "./scripts/variables.sh"

if [[ $MAPR_CLUSTER1_COUNT == 3 ]]; then
    (set -x; ./bin/terraform_apply.sh -var='mapr_cluster_1_count=0' -var='mapr_cluster_2_count=0')

    echo "NOTE: Deleted MAPR clusters will be reinstated after running './bin/terraform_apply.sh'"
fi


