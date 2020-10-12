#!/bin/bash

source "./scripts/variables.sh"
source "./scripts/functions.sh"

aws ec2 describe-instance-types --query 'InstanceTypes[?GpuInfo!=null].[InstanceType]' --output text --region "${REGION}"
