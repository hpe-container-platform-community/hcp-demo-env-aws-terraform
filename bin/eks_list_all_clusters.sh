#!/bin/bash

trap ctrl_c INT

function ctrl_c() {
    echo "Got CTRL-C so quitting..."
    exit
}

REGIONS=$(aws ec2 describe-regions --region us-east-1 --query 'Regions[*].[RegionName] | []' --output text)

for REGION in $REGIONS; do
    tput smul; printf %s\\n "$REGION"; tput rmul
    echo
    aws eks --region $REGION list-clusters
    echo
done