##############################################################
###### You probably won't need to change anything below ######
##############################################################

ssh_prv_key_path   = "./generated/controller.prv_key"
ssh_pub_key_path   = "./generated/controller.pub_key"

vpc_cidr_block     = "10.1.0.0/16"
subnet_cidr_block  = "10.1.0.0/24"

selinux_disabled = true
ad_server_enabled = true # Do not disable this unless you are doing a manual installation

rdp_server_enabled = true # Do not disable this unless you are doing a manual installation
rdp_server_operating_system = "LINUX"
create_eip_rdp_linux_server = false


# you may need to set this if you are deploying your instances in a different region to the s3 bucket on your install binary
epic_dl_url_presign_options = "--region eu-west-1" 

# epic installer options
# epic_options = "--skipeula"                             # epic < 5.2 
epic_options = "--skipeula --default-password admin123"   # epic >= 5.2

create_eip_gateway = true
create_eip_controller = false