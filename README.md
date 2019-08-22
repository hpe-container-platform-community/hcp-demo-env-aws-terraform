### Overview

This project consists of two main parts:

 - A terraform configuration [bluedata_infra.tf](./bluedata_infr.tf) to set up AWS infrastructure for a BlueData deployment
 - A bash script [bluedata_install.sh](./bluedata_install.sh) to automate the installation of BlueData inside the AWS environment

The goals of this project are:

 - Provide the ability for users wishing to manually install BlueData to easily create the required AWS infrastructure.  These users will use the terraform configuration but not the bash script.
 - Provide the ability for users to quickly automate a BlueData install but also have full control of the deployment source code so that they can modify the deployment as they desire.

### Pre-requisites

The following installed locally:

 - python3
 - ssh client
 - ssh key pair (ssh-keygen -t rsa)
 - terraform (https://learn.hashicorp.com/terraform/getting-started/install.html

Script has been tested on Linux and OSX client machines

### Instructions

#### Setup AWS Env and Install BlueData

```
# ensure you have setup your aws credentials (alternatively use 'aws configure' 
# https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
vi ~/.aws/credentials

# clone this project
git clone https://github.com/snowch-bluedata/bluedata-demo-env-aws-terraform
cd bluedata-demo-env-aws-terraform

# create a copy 
cp ./bluedata_infra.tfvars_template to ./bluedata_infra.tfvars

# edit to reflect your requirements
vi ./bluedata_infra.tfvars 

# initialise terraform
terraform init

# create the AWS infastructure with the client_cidr_block for the network access control rules 
# automatically set from the client's IP address

echo MY_IP=$(curl -s http://ifconfig.me/ip)
terraform apply -var-file=bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" -auto-approve=true

   # *NOTE*
   # If the terraform apply command returns an error like `invalid CIDR address: /32`, 
   # check curl actually returned an IP address

# At this point if the apply command finished successfully, you have the AWS infrastructure 
# ready for a BlueData installation.  If you would like to stop at this point and manually 
# install BlueData, you can retrieve the AWS environment details with the command: 
# `terraform output` and then proceed to manually install BlueData inside that environment.

# export the infrastructure details so we can access them from the bluedata_install.sh script
terraform output -json > output.json

# automated installation of BlueData environment
./bluedata_install.sh

# finally, follow instructions output by the above script
```

### Client IP changed?

Re-run to update the AWS network ACL and security groups

```
terraform apply -var-file=bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" 
```

### destroy environment when finished

Note: sometimes destroy gets stuck in a loop - I think this is a terraform bug.  If this happens, manually terminate the instances and re-run the destroy operation.

```
terraform destroy -var-file=bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" 
```

### Shutdown ec2 instances when not in use

For now, you can just use the AWS Management Console or CLI to stop/start your BlueData EC2 instances.  After restarting your instances, re-run the script in the section [client-ip-changed](#client-ip-changed)


