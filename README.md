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

#### Setup AWS Env and Install BlueData

```
# ensure you have setup your aws credentials
vi ~/.aws/credentials

git clone https://github.com/snowch-bluedata/bluedata-demo-env-aws-terraform
cd bluedata-demo-env-aws-terraform

cp ./bluedata_infra.tfvars_template to ./bluedata_infra.tfvars

# edit to reflect your requirements
vi ./bluedata_infra.tfvars 

# initialise terraform
terraform init

# to automatically create the infastructure with the client_cidr_block for the network rules automatically set from the client's IP address
terraform apply -var-file=bluedata_infra.tfvars -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" -auto-approve=true

   # NOTE: if the above command returns an error like `invalid CIDR address: /32`, check curl actually returns an IP address

# At this point, you have the AWS infrastructure ready for a BlueData installation.  
# If you would like to stop at this point and manually install BlueData, you can retrieve the AWS environment details with
# the command: `terraform output`

# export the infrastructure details so we can access them from the bluedata_install.sh script
terraform output -json > output.json

# automated installation of BlueData environment
./bluedata_install.sh

# finally, follow instructions output by script
```

### Client IP changed?

Re-run to update the AWS network ACL and security groups

```
terraform apply -var-file=bluedata_infra.tfvars -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" 
```

### destroy environment when finished

Note: sometimes destroy gets stuck in a loop - I think this is a terraform bug.  If this happens, manually terminate the instances and re-run the destroy operation.

```
terraform destroy -var-file=bluedata_infra.tfvars -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" 
```

### Shutdown ec2 instances when not in use

For now, you can just use the AWS Management Console or CLI to stop/start your BlueData EC2 instances.  After restarting your instancesm re-run the script in the section [client-ip-changed](#client-ip-changed)

TODO: https://groups.google.com/forum/#!topic/terraform-tool/hEESOVOgL_Q

