### Overview

You can share your environment with non-terraform users.

### Pre-requisites

- You must have enabled the RDP server in your `etc/bluedata_infra.tfvars` file (`rdp_server_enabled=true`)
- Don't forget to run `./bin/terraform_apply.bin` after updating variables 

### Instructions

- Non-terraform users will need to install an AWS client
- An IAM user with very limited permissions has been created
- The AWS access and secret key for the IAM user are in `generated/non_terraform_user_scripts.txt`
- The script contains a command allowing users to **start/stop the EC2 instances**
- The script contains a command allowing users to **update the NACL and Security Groups** to permit access from their IP address
- The script contains a command allowing users to **retrieve the RDP host public IP address**

### Optional

- You can provide users access to the environment using a VPN (L2TP+IPSEC)
- You can add additional users to the VPN - see [here](https://github.com/bluedata-community/bluedata-demo-env-aws-terraform/blob/master/docs/README-VPN.md#add-vpn-users)
- It is recommend to enable an EIP for the RDP server in your `etc/bluedata_infra.tf` file (`create_eip_rdp_linux_server=true`) so users don't have to keep updating the VPN server IP address
- Don't forget to run `./bin/terraform_apply.bin` after updating variables 
