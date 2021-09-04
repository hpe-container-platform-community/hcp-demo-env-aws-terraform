#!/bin/bash

REGION=$1
FILTER=$2

if [[ -z $REGION ]];
then
   echo "Usage: $0 aws-region [instance-type-filter]"
   echo
   echo "Examples:"
   echo "          $0 eu-west-3"
   echo "          $0 eu-west-3 m5"
   echo
   exit 1
fi

aws ec2 describe-instance-type-offerings --region $REGION --filters Name=instance-type,Values=${FILTER}* --output text
