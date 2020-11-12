#!/bin/bash

REGIONS=$(aws ec2 describe-regions --region us-east-1 --query 'Regions[*].[RegionName] | []' --output text)

for REGION in $REGIONS; do
    echo $REGION
    echo =======
    aws eks --region $REGION list-clusters
done