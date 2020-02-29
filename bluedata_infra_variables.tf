variable "profile" { default = "default" }
variable "region" { }
variable "az" { }
variable "project_id" { }
variable "user" { }
variable "client_cidr_block" {  }
variable "check_client_ip" { default = "true" }
variable "additional_client_ip_list" { default = [] }
variable "vpc_cidr_block" { }
variable "subnet_cidr_block" { }

variable "EC2_CENTOS7_AMIS" {
  # Find more at https://console.aws.amazon.com/ec2/home?region=us-east-1#Images:visibility=public-images;search=aws-marketplace/CentOS%20Linux%207%20x86_64%20HVM%20EBS%20ENA%201805_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-77ec9308.4
  default = { 
    us-east-1      = "ami-9887c6e7" # N.Virginia
    us-east-2      = "ami-e1496384" # Ohio
    us-west-1      = "ami-4826c22b" # N.California
    us-west-2      = "ami-3ecc8f46" # Oregon
    ap-southeast-1 = "ami-8e0205f2" # Singapore
    eu-central-1   = "ami-dd3c0f36" # Frankfurt
    eu-west-1      = "ami-3548444c" # Ireland 
    eu-west-2      = "ami-00846a67" # London
    eu-west-3      = "ami-262e9f5b" # Paris
    eu-north-1     = "ami-b133bccf" # Stockholm
  } 
} 

variable "EC2_WIN_RDP_AMIS" {
  default = { 
    us-east-1      = "ami-0f969b429284d6156" # N.Virginia
    us-east-2      = "ami-02ec6f788a1f1a739" # Ohio
    us-west-1      = "ami-0a017e6b84bbbca59" # N.California
    us-west-2      = "ami-0bd8c602fafdca7b5" # Oregon
    ap-southeast-1 = "ami-04ea5e0cb6ab293e0" # Singapore
    eu-central-1   = "ami-01ff06d6c38ed6008" # Frankfurt
    eu-west-1      = "ami-0a2b07f79c45eeef1" # Ireland 
    eu-west-2      = "ami-0648c16a1a9bd20dc" # London
    eu-west-3      = "ami-044bb8de8c5a4ebde" # Paris
    eu-north-1     = "ami-08b3a48a0df290fce" # Stockholm
  } 
} 

variable "ssh_prv_key_path" {}
variable "ssh_pub_key_path" {}
variable "worker_count" { default = 3 }

variable "gtw_instance_type" { default = "m4.2xlarge" }
variable "ctr_instance_type" { default = "m4.2xlarge" }
variable "wkr_instance_type" { default = "m4.2xlarge" }
variable "nfs_instance_type" { default = "t2.small" }
variable "ad_instance_type" { default = "t2.small" }
variable "rdp_instance_type" { default = "t2.xlarge" }

variable "epic_dl_url" { }
variable "selinux_disabled" { default = false }

variable "nfs_server_enabled" { default = false }
variable "ad_server_enabled" { default = true }

variable "rdp_server_enabled" { default = false }
variable "windows_username" { }
variable "windows_password" { }

variable "allow_ssh_from_world" {
  default = false
}

variable "allow_rdp_from_world" {
  default = false
}

variable "ca_cert" {
  type = string
}

variable "ca_key" {
  type = string
}
