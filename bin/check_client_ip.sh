#!/bin/bash

source "scripts/variables.sh"

MY_IP="$(curl -s http://ifconfig.me/ip)/32"

if [[ "$CLIENT_CIDR_BLOCK" != "$MY_IP" ]]; 
then
   echo "******************************************************************"
   echo "CLIENT_CIDR_BLOCK: $CLIENT_CIDR_BLOCK"
   echo "http://ifconfig.me/ip: $MY_IP"
   echo 
   echo "Your client IP adddress appears to have changed, you probably need"
   echo "to run the following to update your environment with your new IP  "
   echo "address:"
   echo
   echo "./bin/terraform_apply.sh"
   echo "******************************************************************"
fi

