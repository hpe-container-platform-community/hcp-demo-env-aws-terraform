#!/bin/bash
source "./scripts/variables.sh"

set +u

echo "Stopping instances"
aws --region $REGION --profile $PROFILE ec2 stop-instances \
    --instance-ids $AD_INSTANCE_ID \
    --output table \
    --query "StoppingInstances[*].{ID:InstanceId,State:CurrentState.Name}"