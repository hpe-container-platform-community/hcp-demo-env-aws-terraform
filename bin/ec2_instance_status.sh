#!/bin/bash
source "./scripts/variables.sh"

aws --region ${REGION} --profile ${PROFILE} ec2 describe-instances \
    --instance-ids ${ALL_INSTANCE_IDS} \
    --output table \
    --query "Reservations[*].Instances[*].{ExtIP:PublicIpAddress,IntIP:PrivateIpAddress,ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key=='Name']|[0].Value} | [][] | sort_by(@, &Name)"