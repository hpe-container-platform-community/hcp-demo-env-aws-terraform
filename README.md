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
terraform apply -var-file=bluedata_demo.tfvars -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32"

# inspect the output for errors if no errors you should see a configuration URL

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
