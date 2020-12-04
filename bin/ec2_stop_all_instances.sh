#!/bin/bash

set -u

source "./scripts/variables.sh"
source "scripts/functions.sh"


if [[  "$CREATE_EKS_CLUSTER" == "True" ]]; then
    EKS_CLUSTER_NAME=$(terraform output eks-cluster-name)

    CLUSTER_STATUS=$(aws eks --region eu-west-3 --profile default \
        describe-cluster --name ${EKS_CLUSTER_NAME} \
        --query 'cluster.status')

    echo
    echo "You have the following EKS clusters:"
    echo
    echo ${EKS_CLUSTER_NAME}: ${CLUSTER_STATUS}

    print_term_width '='
    echo
    echo "You have the following EKS instances:"
    echo

    aws ec2 describe-instances --region $REGION --profile $PROFILE \
        --filters Name=tag:eks:nodegroup-name,Values=${EKS_CLUSTER_NAME},${EKS_CLUSTER_NAME}-2 \
        --output table \
        --query "Reservations[*].Instances[*].{ExtIP:PublicIpAddress,IntIP:PrivateIpAddress,ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key=='Name']|[0].Value} | [][] | sort_by(@, &Name)"  

    echo
    echo "You have the following EKS nodegroups:"
    echo
    aws eks list-nodegroups --region $REGION --profile $PROFILE --cluster-name ${EKS_CLUSTER_NAME} --output text
    echo
    echo "To delete the EKS instances you need to remove the node group: e.g."
    echo
    tput setaf 1
    echo "aws eks delete-nodegroup --region $REGION --profile $PROFILE --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_CLUSTER_NAME"
    echo "aws eks delete-nodegroup --region $REGION --profile $PROFILE --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_CLUSTER_NAME-2"
    tput sgr0
    echo
    echo "The instances will be recreated with './bin/terraform_apply.sh'"
    echo
    print_term_width '='
fi

SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=1 -q"
CMD='nohup sudo halt -n </dev/null &'

set +u

{
    if [[ -n $WRKR_PUB_IPS ]]; then
        echo "Sending 'sudo halt -n' to all worker hosts for graceful shutdown."
        for HOST in ${WRKR_PUB_IPS[@]}; do
            ssh $SSH_OPTS -i "$LOCAL_SSH_PRV_KEY_PATH" centos@$HOST "$CMD" || true
        done
        echo "Sleeping 120s allowing halt to complete before issuing 'ec2 stop-instances' command"
        sleep 120
    fi
} &

{
    if [[ -n $GATW_PUB_IP ]]; then
        echo "Sending 'sudo halt -n' to gateway host for graceful shutdown."
        ssh $SSH_OPTS -i "$LOCAL_SSH_PRV_KEY_PATH" centos@$GATW_PUB_IP "$CMD" || true
        echo "Sleeping 120s allowing halt to complete before issuing 'ec2 stop-instances' command"
        sleep 120
    fi
} &

{
    if [[ -n $CTRL_PUB_IP ]]; then
        echo "Sending 'sudo halt -n' to controller host for graceful shutdown."
        ssh $SSH_OPTS -i "$LOCAL_SSH_PRV_KEY_PATH" centos@$CTRL_PUB_IP "$CMD" || true
        echo "Sleeping 120s allowing halt to complete before issuing 'ec2 stop-instances' command"
        sleep 120
    fi
} &

wait

echo "Running aws 'stop-instances' non-EKS instances"
aws --region $REGION --profile $PROFILE ec2 stop-instances \
    --instance-ids $ALL_INSTANCE_IDS \
    --output table \
    --query "StoppingInstances[*].{ID:InstanceId,State:CurrentState.Name}"
