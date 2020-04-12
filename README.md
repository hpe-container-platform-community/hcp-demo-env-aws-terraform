**OVERVIEW**

This project makes it easy to setup HPE Container Platform demo/trial environments on AWS

### Pre-requisites

The following installed locally:

 - terraform (https://learn.hashicorp.com/terraform/getting-started/install.html
 - aws cli (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

This project has been tested on **Linux** and **OSX** client machines - Windows is unlikely to work.

### Quick start

#### Setup environment

```
# If you haven't already configured the aws CLI with your credentials, run the following:
aws configure

# clone this project
git clone https://github.com/bluedata-community/bluedata-demo-env-aws-terraform
cd bluedata-demo-env-aws-terraform

# create a copy 
cp ./etc/bluedata_infra.tfvars_example ./etc/bluedata_infra.tfvars

# edit to reflect your requirements
vi ./etc/bluedata_infra.tfvars 

# initialise terraform
terraform init
```

We are now ready to automate the environment setup ...

```
./bin/create_new_environment_from_scratch.sh
```

If the above script has run without error, you can retrieve the RDP/brower endpoint and credentials using:

```
./generated/rdp_credentials.sh
```

Use a Remote Desktop Client or open a webbrowser into the RDP host. You are then ready to configure your HPE Container Platform deployment with Gateways, Hosts, License, etc.



## Advanced documentation

See [./docs/README-ADVANCED.md](./docs/README-ADVANCED.md) for information on **stopping**, **starting** from AWS instances and more.

See [./docs/README-TROUBLESHOOTING.md](./docs/README-TROUBLESHOOTING.md) for troubleshooting help.
