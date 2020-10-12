#!/bin/bash

REGION=$1

if [[ -z "$REGION" ]];
then
    echo Usage: $0 AWS-REGION
    echo
    echo        Example: 
    echo        --------
    echo        $0 eu-west-2
    exit 1
fi


aws ec2 describe-instance-types --query 'InstanceTypes[?GpuInfo!=null].[InstanceType]' --output text --region "${REGION}"
