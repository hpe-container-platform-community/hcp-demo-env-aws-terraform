Design Principles
=================

# Separation of infrastructure and software deployment

This project has been designed to provide separation of concerns as much as possible:

- Infrastructure setup
- HPE Container Platform (HCP) setup

The infrastructure setup is performed by Terraform and provides the AWS components required for running HCP and other services such as a RDP Jump Host and an Active Directory Server.

Post infrastructure setup, the setup of HCP is peformed by a bash script: `./scripts/bluedata_intall.sh`.  

The separation of concerns has two main goals:

1. The user can choose to only setup the infrastructure and then manually install HCP (this is good for learning how to manually deploy HCP)
2. The non-infrastucture setup is performed using a shell script, so should be easy to read and understand how to perform a manual deployment of HCP.  It is for this reason that ansible or other technologies have not been used for the post infrastructure setup.

# Idempotent Scripts

Scripts are idempotent as much as possible. 

For more information see https://www.infoworld.com/article/3263724/idempotence-and-the-discipline-of-devops.html

