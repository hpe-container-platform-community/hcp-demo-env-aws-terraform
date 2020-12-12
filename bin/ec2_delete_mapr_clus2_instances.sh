#!/bin/bash

source "./scripts/variables.sh"

if [[ $MAPR_CLUSTER1_COUNT == 3 ]]; then
    (set -x; ./bin/terraform_apply.sh -var='mapr_cluster_2_count=0')

    echo "NOTE: Deleted MAPR cluster will be reinstated after running './bin/terraform_apply.sh'"
fi


