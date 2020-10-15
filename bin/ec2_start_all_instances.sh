#!/bin/bash

source "./scripts/variables.sh"

aws --region $REGION --profile $PROFILE ec2 start-instances \
    --instance-ids $ALL_INSTANCE_IDS \
    --output table \
    --query "StartingInstances[*].{ID:InstanceId,State:CurrentState.Name}"

CURR_CLIENT_CIDR_BLOCK="$(curl -s http://ifconfig.me/ip)/32"

# check if the client IP address has changed
if [[ "$CLIENT_CIDR_BLOCK" = "$CURR_CLIENT_CIDR_BLOCK" ]]; then
    UPDATE_COMMAND="refresh"
else
    UPDATE_COMMAND="apply"
fi

echo "***********************************************************************************************************"
echo "IMPORTANT: You need to run the following command to update your local state:"
echo
echo "           ./bin/terraform_$UPDATE_COMMAND.sh"
echo 
echo "           If you encounter an error running ./bin/terraform_$UPDATE_COMMAND.sh it is probably because your"
echo "           instances are not ready yet.  You can check the instances status with:"
echo 
echo "           ./generated/cli_running_ec2_instances.sh"
echo "***********************************************************************************************************"