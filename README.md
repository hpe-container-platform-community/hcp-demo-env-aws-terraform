**OVERVIEW**

This project makes it easy to setup HPE Container Platform demo/trial environments on AWS

```diff
- The goal of this project is to easily create HPE Container Platform demo and trial environments.
- The concepts demonstrated in this project are not suitable for production environments.
- This project is for frequently creating and tearing down demo/trial environments.
- This project is not for creating and managing long-living demo/trial environments.
- Please read the project license before using this project.
```

**IMPORTANT:** If you haven't yet had any exposure to HPE Container Platform, you should head to [HPE Demonstration Portal](https://hpedemoportal.ext.hpe.com/) (search for HPE Container Plaftorm) where you can schedule to run some demo workflows.  This is available for HPE Employees and Partners only.

### Pre-requisites

The following installed locally:

 - Terraform - [installation instructions](https://learn.hashicorp.com/terraform/getting-started/install.html)|[downloads](https://www.terraform.io/downloads.html)
 - AWS CLI - [installation instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

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



## Further documentation

[README](./docs/README-EC2-START-STOP-STATUS.md) for **stopping**, **starting** and **viewing the status** of your EC2 instances

[README](./docs/README-RDP.md) for **information** on your pre-configured **RDP Server** 

[README](./docs/README-DESTROY-DEMO-ENV.md) for **destroying** your demo environment in AWS

[README](./docs/README-ADDING-MORE-WORKERS.md) for **increasing worked node counts**.

[README](./docs/README-TROUBLESHOOTING.MD) for troubleshooting help.

[README](./docs/README-AD.md) for information on setting up HCP with Active Directory/LDAP.

[README](./docs/README-MAPR-LDAP.md) for information on setting up MAPR  with Active Directory/LDAP.

[README](./docs/README-DATA-FABRIC-OVERVIEW.md) for information on the data fabric architecture.

[README](./docs/README-DATA-TIERING.md) for information on setting up MAPR data tiering.

[README](./docs/README-DESIGN-PRINCIPLES.md) why this project is architected the way it is.

[README](./docs/README-VPN.md) how to **create a vpn** to your AWS deployment
