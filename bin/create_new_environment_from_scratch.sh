#!/bin/bash

if [[ -f terraform.tfstate ]];
then
   echo "********************************************************************************************************"
   echo "Refusing to create environment because existing ./terraform.tfstate file found."
   echo "Please destroy your environment (./bin/terraform_destroy.sh) and then remove all terraform.tfstate files"
   echo "before trying again."
   echo "********************************************************************************************************"
   exit 1
fi

terraform apply -var-file=etc/bluedata_infra.tfvars -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" -auto-approve=true && \
sleep 60 && \
terraform output -json > generated/output.json && \
./scripts/bluedata_install.sh

