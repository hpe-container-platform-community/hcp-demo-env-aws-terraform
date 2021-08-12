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