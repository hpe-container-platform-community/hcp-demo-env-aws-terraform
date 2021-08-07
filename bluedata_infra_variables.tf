variable "profile" { default = "default" }
variable "region" { }
variable "az" { }
variable "project_id" { }
variable "client_cidr_block" {  }
variable "check_client_ip" { default = "true" }
variable "additional_client_ip_list" { default = [] }
variable "vpc_cidr_block" { }
variable "subnet_cidr_block" { }

variable "create_iam_user" { default = "false" }

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
    ca-central-1   = "ami-e802818c" # Canada
  } 
}

variable "EC2_UBUNTU1804_AMIS" {
  # Find more at https://console.aws.amazon.com/ec2/home?region=us-east-1#Images:visibility=public-images;search=aws-marketplace/CentOS%20Linux%207%20x86_64%20HVM%20EBS%20ENA%201805_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-77ec9308.4
  default = { 
    us-east-1      = "ami-06c075a638fee778f" # N.Virginia
    us-east-2      = "ami-0ee5e851705bfaf7a" # Ohio
    us-west-1      = "ami-0eedd569ba78a4bbc" # N.California
    us-west-2      = "ami-01cfa0ce6fe1024f8" # Oregon
    ap-southeast-1 = "ami-088d07b5c35876923" # Singapore
    eu-central-1   = "ami-060e472760062f83f" # Frankfurt
    eu-west-1      = "ami-02f7235fe5805da91" # Ireland 
    eu-west-2      = "ami-0978f2d57755c6503" # London
    eu-west-3      = "ami-0d857c06968b4f4fb" # Paris
    eu-north-1     = "ami-0991deb71c7c7537f" # Stockholm
    ca-central-1   = "ami-0aefe348b9802b0fd" # Canada
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
    ca-central-1   = "ami-08b3a48a0df290fce" # Dummy Canada
  } 
} 

variable "EC2_LIN_RDP_AMIS" {
  // https://aws.amazon.com/marketplace/pp/B07LBG6YGB?ref=cns_srchrow
  default = { 
    us-east-1      = "ami-009a1990c909367e6" # N.Virginia
    us-east-2      = "ami-019399e9349e4e468" # Ohio
    us-west-1      = "ami-077af8ef25b856d91" # N.California
    us-west-2      = "ami-08402b04e312d056c" # Oregon
    ap-southeast-1 = "ami-030efc4ccdc159ea6" # Singapore
    eu-central-1   = "ami-06d9c83ef2e37956e" # Frankfurt
    eu-west-1      = "ami-06a4237b5ad3df8ab" # Ireland 
    eu-west-2      = "ami-05445e3ee29659931" # London
    eu-west-3      = "ami-0aa2d4577e73e16cc" # Paris
    eu-north-1     = "ami-0d1087ff408c45456" # Stockholm
    ca-central-1   = "ami-0a417d04a877ebc08" # Canada
  } 
} 

variable "create_eip_controller" { 
  default = false
}

variable "create_eip_gateway" { 
  default = false
}

variable "create_eip_rdp_linux_server" { 
  default = false
}

variable "embedded_df" { 
  default = true
}

variable "create_eks_cluster" { 
  default = false
}
variable "eks_subnet2_cidr_block" {
  default = "10.1.2.0/24"
}
variable "eks_subnet3_cidr_block" {
  default = "10.1.3.0/24"
}
variable "eks_subnet2_az_suffix" {
  default = "b"
}
variable "eks_subnet3_az_suffix" {
  default = "c"
}
variable "eks_scaling_config_desired_size" {
  default = 1
}
variable "eks_scaling_config_max_size" {
  default = 1
}
variable "eks_scaling_config_min_size" {
  default = 1
}
variable "eks_instance_type" {
  default = "t2.micro"
}


variable "install_with_ssl" {
    default = true
}

variable "ssh_prv_key_path" {}
variable "ssh_pub_key_path" {}
variable "worker_count" { default = 3 }

variable "mapr_cluster_1_count" { default = 0 }
variable "mapr_cluster_1_name" { default = "demo1.mapr.com" }
variable "mapr_cluster_2_count" { default = 0 }
variable "mapr_cluster_2_name" { default = "demo2.mapr.com" }

variable "gpu_worker_count" { default = 0 }
variable "gpu_worker_instance_type" {
  default = ""
}
variable "gpu_worker_has_disk_for_df" {
  default = false
} 

variable "gtw_instance_type" { default = "m4.2xlarge" }
variable "ctr_instance_type" { default = "m4.2xlarge" }
variable "wkr_instance_type" { 
  type = string
  default = "m4.2xlarge" 
}
variable "wkr_instance_types" { 
  type    = list
  default = null
}
variable "nfs_instance_type" { default = "t2.small" }
variable "ad_instance_type" { default = "t2.small" }
variable "rdp_instance_type" { default = "t2.xlarge" }
variable "mapr_instance_type" { default = "m4.2xlarge" }

variable "epic_dl_url" { }
variable "epid_dl_url_needs_presign" { default = false }
variable "epic_dl_url_presign_options" { default = "" }
variable "epic_options" { default = "" }
variable "selinux_disabled" { default = false }

variable "nfs_server_enabled" { default = false }
variable "ad_server_enabled" { default = true }
variable "ad_member_group" { default = "DemoTenantUsers" }
variable "ad_admin_group" { default = "DemoTenantAdmins" }

variable "dns_zone_name" {
  default = "samdom.example.com"
}

variable "enable_route53_private_dns" { default = true }

variable "rdp_server_enabled" { default = true }

variable "rdp_server_operating_system" {
  type = string
  default = "LINUX"
  validation {
    condition = var.rdp_server_operating_system == "WINDOWS" || var.rdp_server_operating_system == "LINUX"
    error_message = "Valid values: WINDOWS | LINUX."
  }
}

variable "allow_ssh_from_world" {
  default = false
}

variable "allow_rdp_from_world" {
  default = false
}

variable "softether_cidr_block" {
  default = "192.168.30.0/24"
}

variable "softether_rdp_ip" {
  default = "192.168.30.1"
}