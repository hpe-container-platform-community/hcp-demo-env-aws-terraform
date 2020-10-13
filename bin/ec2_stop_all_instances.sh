#!/bin/bash
source "./scripts/variables.sh"

SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=1 -q"
CMD='nohup sudo halt -n </dev/null &'

echo "Sending 'sudo halt -n' to all hosts for graceful shutdown."

if [[ -n $WRKR_PUB_IPS ]]; then
    for HOST in $${WRKR_PUB_IPS[@]}; do
        ssh $SSH_OPTS -i "$LOCAL_SSH_PRV_KEY_PATH" centos@$HOST "$CMD" || true
    done
fi

if [[ -n $GATW_PUB_IP ]]; then
    ssh $SSH_OPTS -i "$LOCAL_SSH_PRV_KEY_PATH" centos@$GATW_PUB_IP "$CMD" || true
fi

if [[ -n $CTRL_PUB_IP ]]; then
    ssh $SSH_OPTS -i "$LOCAL_SSH_PRV_KEY_PATH" centos@$CTRL_PUB_IP "$CMD" || true
fi

echo "Sleeping 120s allowing halt to complete before issuing 'ec2 stop-instances' command"
sleep 120

echo "Stopping instances"
aws --region $REGION --profile $PROFILE ec2 stop-instances \
    --instance-ids $ALL_INSTANCE_IDS \
    --output table \
    --query "StoppingInstances[*].{ID:InstanceId,State:CurrentState.Name}"