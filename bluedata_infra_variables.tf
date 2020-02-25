variable "profile" { default = "default" }
variable "region" { }
variable "az" { }
variable "project_id" { }
variable "user" { }
variable "client_cidr_block" {  }
variable "check_client_ip" { default = "true" }
variable "vpc_cidr_block" { }
variable "subnet_cidr_block" { }

// TODO - this is currently unused
variable "EC2_CENTOS7_AMIS" {
  # Find more https://console.aws.amazon.com/ec2/home?region=us-east-1#Images:visibility=public-images;search=aws-marketplace/CentOS%20Linux%207%20x86_64%20HVM%20EBS%20ENA%201805_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-77ec9308.4
  default = { 
    us-east-1      = "ami-9887c6e7" # N.Virginia
    us-east-2      = "ami-e1496384" # Ohio
    us-west-1      = "ami-4826c22b" # N.California
    us-west-2      = "ami-3ecc8f46" # Oregon
    ap-southeast-1 = "ami-8e0205f2" # Singapore
    # TODO complete this ...
    /* "ami-00846a67" # this is valid for the London region, change if required
                                    #
                                    # Frankfurt  : ami-dd3c0f36 ?
                                    # Ireland    : ami-3548444c
                                    # London     : ami-00846a67
                                    # Paris      : ami-262e9f5b
                                    # Stockholm  : ami-b133bccf ?
                                    */
  } 
} 
// var.ec2_ami = var.EC2_CENTOS7_AMIS[var.region]

variable "ec2_ami" { }

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
