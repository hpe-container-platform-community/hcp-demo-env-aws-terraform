// Usage: terraform <action> -var-file="etc/bluedata_infra.tfvars"

terraform {
  required_version = ">= 0.12.21"
  required_providers {
    aws = ">= 2.25.0"
  }
}

/******************* setup region and az ********************/

provider "aws" {
  profile = var.profile
  region  = var.region
}

data "aws_availability_zone" "main" {
  name = var.az
}

/******************* verify client ip ********************/

data "external" "example1" {
 program = [ "python3", "${path.module}/scripts/verify_client_ip.py", "${var.client_cidr_block}", "${var.check_client_ip}" ]
}

/******************* ssh pub key content ********************/

data "local_file" "ssh_pub_key" {
    filename = var.ssh_pub_key_path
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_id}-keypair"
  public_key = data.local_file.ssh_pub_key.content
}

/******************* modules ********************/

module "network" {
  source = "./modules/module-network"
  project_id = var.project_id
  user = var.user
  client_cidr_block = var.client_cidr_block
  subnet_cidr_block = var.subnet_cidr_block
  vpc_cidr_block = var.vpc_cidr_block
  aws_zone_id = data.aws_availability_zone.main.zone_id
  allow_ssh_from_world = var.allow_ssh_from_world
  allow_rdp_from_world = var.allow_rdp_from_world
}

module "nfs_server" {
  source = "./modules/module-nfs-server"
  project_id = var.project_id
  user = var.user
  ssh_prv_key_path = var.ssh_prv_key_path
  nfs_ec2_ami = var.EC2_CENTOS7_AMIS[var.region]
  nfs_instance_type = var.nfs_instance_type
  nfs_server_enabled = var.nfs_server_enabled
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = [ module.network.security_group_main_id ]
  subnet_id = module.network.subnet_main_id
}

module "ad_server" {
  source = "./modules/module-ad-server"
  project_id = var.project_id
  user = var.user
  ssh_prv_key_path = var.ssh_prv_key_path
  ad_ec2_ami = var.EC2_CENTOS7_AMIS[var.region]
  ad_instance_type = var.ad_instance_type
  ad_server_enabled = var.ad_server_enabled
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = [ module.network.security_group_main_id ]
  subnet_id = module.network.subnet_main_id
}

module "rdp_server" {
  source = "./modules/module-rdp-server"
  project_id = var.project_id
  user = var.user
  ssh_prv_key_path = var.ssh_prv_key_path
  rdp_ec2_ami = var.rdp_ec2_ami # TODO: switch to var.EC2_WINDOWS_AMIS[var.region]
  rdp_instance_type = var.rdp_instance_type
  rdp_server_enabled = var.rdp_server_enabled
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = [ module.network.security_group_main_id ]
  subnet_id = module.network.subnet_main_id
  windows_username = var.windows_username
  windows_password = var.windows_password
}