#!/bin/bash
source "./scripts/variables.sh"

set +u

SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=1 -q"
CMD='nohup sudo halt -n </dev/null &'

echo "Sending 'sudo halt -n' to all hosts for graceful shutdown."

if [[ -n $MAPR_CLUSTER1_HOSTS_PUB_IPS ]]; then
    for HOST in ${MAPR_CLUSTER1_HOSTS_PUB_IPS[@]}; do
        echo "Halting $HOST"
        ssh $SSH_OPTS -i "$LOCAL_SSH_PRV_KEY_PATH" ubuntu@$HOST "$CMD" || true
    done
fi

if [[ -n $MAPR_CLUSTER2_HOSTS_PUB_IPS ]]; then
    for HOST in ${MAPR_CLUSTER2_HOSTS_PUB_IPS[@]}; do
        echo "Halting $HOST"
        ssh $SSH_OPTS -i "$LOCAL_SSH_PRV_KEY_PATH" ubuntu@$HOST "$CMD" || true
    done
fi

echo "Sleeping 120s allowing halt to complete before issuing 'ec2 stop-instances' command"
sleep 120

echo "Stopping instances"
aws --region $REGION --profile $PROFILE ec2 stop-instances \
    --instance-ids $ALL_MAPR_INSTANCE_IDS \
    --output table \
    --query "StoppingInstances[*].{ID:InstanceId,State:CurrentState.Name}"