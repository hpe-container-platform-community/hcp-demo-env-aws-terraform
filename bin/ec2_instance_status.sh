#!/bin/bash
source "./scripts/variables.sh"

aws --region ${REGION} --profile ${PROFILE} ec2 describe-instances \
    --instance-ids ${ALL_INSTANCE_IDS} \
    --output table \
    --query "Reservations[*].Instances[*].{ExtIP:PublicIpAddress,IntIP:PrivateIpAddress,ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key=='Name']|[0].Value} | [][] | sort_by(@, &Name)"


if [[  "$CREATE_EKS_CLUSTER" == "True" ]]; then
    EKS_CLUSTER_NAME=$(terraform output eks-cluster-name)

    CLUSTER_STATUS=$(aws eks --region eu-west-3 --profile default \
        describe-cluster --name ${EKS_CLUSTER_NAME} \
        --query 'cluster.status')

    echo
    echo "You have the following EKS clusters:"
    echo
    echo ${EKS_CLUSTER_NAME}: ${CLUSTER_STATUS}

    echo
    echo "You have the following EKS EC2 instances:"
    echo

    aws ec2 describe-instances --region $REGION --profile $PROFILE --filters Name=tag:eks:nodegroup-name,Values=${EKS_CLUSTER_NAME} --output table \
        --query "Reservations[*].Instances[*].{ExtIP:PublicIpAddress,IntIP:PrivateIpAddress,ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key=='Name']|[0].Value} | [][] | sort_by(@, &Name)"  

    echo
    echo "To delete the EKS instances you need to remove the node group: e.g."
    echo
    tput setaf 1
    echo "aws eks delete-nodegroup --region $REGION --profile $PROFILE --cluster-name $EKS_CLUSTER_NAME --nodegroup-name $EKS_CLUSTER_NAME"
    tput sgr0
    echo
    echo "The instances will be reinstated with './bin/terraform_apply.sh'"
    echo
fi