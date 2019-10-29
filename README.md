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

#### Setup variables and terraform

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
```

If you are working with BD 5x we need a different initial configuration:

```
ln -s ./initial_bluedata_config_5x.py ./initial_bluedata_config.py
```

We are now ready to go ...

```
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

# set the defaults for the initial BlueData configuration 
# if you want to manually perform the initial BlueData configuration, skip this step
# - this step has not been tested with BlueData 5x

./bluedata_config.sh 

# finally, follow instructions output by `bluedata_install.sh`
```

Or, all together ...

```
echo MY_IP=$(curl -s http://ifconfig.me/ip) && \
terraform apply \
   -var-file=bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" \
   -auto-approve=true && \
terraform output -json > output.json && \
./bluedata_install.sh && \
./bluedata_config.sh 
```

Tip - if your epic download url is set for private access, you can create a presigned url using this:

```
EPIC_PRV_URL=s3://yourbucket/your.bin
echo MY_IP=$(curl -s http://ifconfig.me/ip) && \
terraform apply \
   -var-file=bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" \
   -var="epic_dl_url=$(aws s3 presign $EPIC_PRV_URL)" \
   -auto-approve=true && \
terraform output -json > output.json && \
./bluedata_install.sh && \
./bluedata_config.sh 
```

### Setup a NFS server (optional)

If you want the terraform script to deploy a NFS server (e.g. for ML OPS projects), set `nfs_server_enabled=true` in your `bluedata_infra.tfvars` file.

You will need to run `terraform apply ...` after making the update.  

Run `terraform output nfs_server_private_ip` to get the NFS server ip address.  The nfs share is set as `/nfsroot`.

### Setup an Active Directory (optional)

See [./README-AD.md](./README-AD.md) for more information.

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
# don't forget to approve when prompted
terraform destroy -var-file=bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" 
```

### Shutdown ec2 instances when not in use

Some scripts were generated by terraform for this:

- `./generated/cli_stop_ec2_instances.sh` to stop your instances
- `./generated/cli_start_ec2_instances.sh` to start your instances
- `./generated/cli_running_ec2_instances.sh` to view running instances

