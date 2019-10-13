### Overview

This project consists of two main parts:

 - A terraform configuration [bluedata_infra.tf](./bluedata_infra.tf) to set up AWS infrastructure for a BlueData 4.x deployment
 - A bash script [bluedata_install.sh](./bluedata_install.sh) to automate the installation of BlueData 4.x inside the AWS environment

The goals of this project are:

 - Provide the ability for users wishing to manually install BlueData to easily create the required AWS infrastructure.  These users will use the terraform configuration but not the bash script.
 - Provide the ability for users to quickly automate a BlueData install but also have full control of the deployment source code so that they can modify the deployment as they desire.

### Pre-requisites

The following installed locally:

 - python3
 - ssh client
 - ssh key pair (ssh-keygen -t rsa)
 - terraform (https://learn.hashicorp.com/terraform/getting-started/install.html
 - curl client
 - aws cli (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

This project has been tested on Linux and OSX client machines

### Instructions

#### Setup AWS Env and Install BlueData

```
# ensure you have setup your aws credentials (alternatively use 'aws configure' 
# https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
vi ~/.aws/credentials

# clone this project
git clone https://github.com/bluedata-community/bluedata-demo-env-aws-terraform
cd bluedata-demo-env-aws-terraform

# create a copy 
cp ./bluedata_infra.tfvars_template ./bluedata_infra.tfvars

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

Or, all together ...

```
echo MY_IP=$(curl -s http://ifconfig.me/ip) && \
terraform apply -var-file=bluedata_infra.tfvars -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" -auto-approve=true && \
terraform output -json > output.json && \
./bluedata_install.sh
```

### Setup a NFS server

If you want the terraform script to deploy a NFS server (e.g. for ML OPS projects), set `nfs_server_enabled=true` in your `bluedata_infra.tfvars` file.

You will need to run `terraform apply ...` after making the update.  

Inspect `terraform output` for the `nfs_server_private_ip`.  The nfs share is set as `/nfsroot`.

### Setup an Active Directory server

If you want the terraform script to deploy an AD server, set `ad_server_enabled=true` in your `bluedata_infra.tfvars` file.

You will need to run `terraform apply ...` after making the update.  

Inspect `terraform output` for the `ad_server_private_ip` - you will need this when configuring the BlueData UI.

```
System Settings -> User Authentication
   -> Authentication Type: Active Directory
   -> Security Protocol: LDAPS
   -> Service Location: ${ad_server_private_ip} -> Port: 636
   -> Bind Type: Search Bind
   -> User Attribute: sAMAccountName
   -> Base DN: CN=Users,DC=samdom,DC=example,DC=com
   -> Bind DN: cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com
   -> Bind Password: adpassword

```

TODO: How to add users to Active Directory.  

### Client IP changed?

Re-run to update the AWS network ACL and security groups

```
terraform apply -var-file=bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" 
```

### Add more workers?

Set the variable `worker_count=` in `bluedata_infra.tfvars` to the desired number.

```
# don't forget to approve when prompted
terraform apply -var-file=bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" 

# update the json data
terraform output -json > output.json

# run a script to prepare the worker - follow the prompts and instructions.
./bluedata_prepare_worker.sh
```

### Destroy environment when finished

```
terraform destroy -var-file=bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" 
```

### Shutdown ec2 instances when not in use

Some scripts were generated by terraform for this:

- `./generated/cli_stop_ec2_instances.sh` to stop your instances
- `./generated/cli_start_ec2_instances.sh` to start your instances
- `./generated/cli_running_ec2_instances.sh` to view running instances

