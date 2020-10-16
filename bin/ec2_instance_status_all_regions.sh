#!/bin/bash

source "./scripts/variables.sh"

for curr_region in $(aws ec2 --region ${REGION} describe-regions --output text | cut -f4); do
    echo -e "\nListing Instances Status in region:'${curr_region}' ... matching '${USER_TAG}' ";
    aws ec2 --region $curr_region describe-instances \
        --query "Reservations[*].Instances[*].{IP:PublicIpAddress,ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[0].Value}" \
        --filters Name=instance-state-name,Values=running \
        --filters Name=tag:user,Values=${USER_TAG} \
        --output=table
done