### Overview

This project is a work-in-progress.

### Instructions

<!-- language: bash -->

```
# ensure you have setup your aws credentials
vi ~/.aws/credentials

git clone https://github.com/snowch-bluedata/bluedata-demo-env-aws-terraform
cd bluedata-demo-env-aws-terraform

cp ./bluedata_demo.tfvars_template to ./bluedata_demo.tfvars

# edit to reflect your requirements
vi ./bluedata_demo.tfvars 

# install terraform - https://learn.hashicorp.com/terraform/getting-started/install.html
terraform init

# deploy BlueData to AWS
terraform apply -var-file=bluedata_demo.tfvars

# or to automatically set client_cidr_block from the client's IP
terraform apply -var-file=bluedata_demo.tfvars -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" -var="continue_on_precheck_fail=\"true\""

# inspect the output for errors if no errors you should see a configuration URL

# Config
# 1. Insert the gateway private ip address

# Add workers and gateway
# 1. Add workers private ip
# 2. Add gateway private ip and dns
# 3. Retrive contoller ssh key: ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa centos@XXXXXX "cat ~/.ssh/id_rsa" > controller.prv_key
# 4. Set ssh key

ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa centos@35.176.105.120 "cat ~/.ssh/id_rsa" > controller.prv_key

# destroy environment when finished
terraform destroy -var-file=bluedata_demo.tfvars
```

### TODO - shutdown ec2 instances when not in use

See https://groups.google.com/forum/#!topic/terraform-tool/hEESOVOgL_Q

### Destroy and Apply

```
terraform destroy -var-file=bluedata_demo.tfvars -auto-approve && terraform apply -var-file=bluedata_demo.tfvars -auto-approve
```
# bluedata-demo-env-aws-terraform
