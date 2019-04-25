### Overview

This project is a work-in-progress.

### Pre-requisites

The following installed locally:

 - python3
 - ssh client
 - ssh key pair (ssh-keygen -t rsa)
 - terraform (https://learn.hashicorp.com/terraform/getting-started/install.html)

Script has only been tested on Linux machine

### Instructions

```
# ensure you have setup your aws credentials
vi ~/.aws/credentials

git clone https://github.com/snowch-bluedata/bluedata-demo-env-aws-terraform
cd bluedata-demo-env-aws-terraform

cp ./bluedata_demo.tfvars_template to ./bluedata_demo.tfvars

# edit to reflect your requirements
vi ./bluedata_demo.tfvars 

# initialise terraform
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
# 3. Retrive contoller ssh key - see `terraform output`
# 4. Set ssh key

# destroy environment when finished
terraform destroy -var-file=bluedata_demo.tfvars -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" 
```

### TODO - shutdown ec2 instances when not in use

See https://groups.google.com/forum/#!topic/terraform-tool/hEESOVOgL_Q

