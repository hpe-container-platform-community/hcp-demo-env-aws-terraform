variable "profile" { default = "default" }
variable "region" { }
variable "az" { }
variable "project_id" { }
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

variable "EC2_LIN_RDP_AMIS" {
  // https://aws.amazon.com/marketplace/pp/B07LBG6YGB?ref=cns_srchrow
  default = { 
    us-east-1      = "ami-08cf3d19c50987ffc" # N.Virginia
    us-east-2      = "ami-022a505199d19fbe4" # Ohio
    us-west-1      = "ami-0849ceb9ac3066e90" # N.California
    us-west-2      = "ami-016fcfe2d5ccf859a" # Oregon
    ap-southeast-1 = "ami-07dd34d19c20168bf" # Singapore
    eu-central-1   = "ami-03dbefae8333132eb" # Frankfurt
    eu-west-1      = "ami-0fbaf7a1071b50d9c" # Ireland 
    eu-west-2      = "ami-05748056eed47d81b" # London
    eu-west-3      = "ami-0c432dc2d9e9a1420" # Paris
    eu-north-1     = "ami-01a16aeb746ea52eb" # Stockholm
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
variable "wkr_instance_type" { default = "m4.2xlarge" }
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

variable "dns_zone_name" {
  default = "samdom.example.com"
}

variable "enable_route53_private_dns" { default = false }

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


variable "ca_cert" {
  default =<<EOF
-----BEGIN CERTIFICATE-----
MIIDSzCCAjOgAwIBAgIIPkySS+2b3eIwDQYJKoZIhvcNAQELBQAwIDEeMBwGA1UE
AxMVbWluaWNhIHJvb3QgY2EgM2U0YzkyMCAXDTIwMDIyOTE4MTk1MFoYDzIxMjAw
MjI5MTgxOTUwWjAgMR4wHAYDVQQDExVtaW5pY2Egcm9vdCBjYSAzZTRjOTIwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCa4GCA9HSEGfJ1l9c+ccA8D6xI
b2LED7ud924at+Qs24ZGXus3GVTSKUVxeuIESm/f10I1UW1Q8kn9lESjWNGks+uO
vE/q8KCxgww2HL2o/gmTn3fATQ+QCexRiiXcNlPezzAMuyZJETTKUSDh/UPUMiNd
KevqHr8706BqMURSdr06QZ+QkOv3+FjiJDCblxx6t2PSMOI+RZEjYlFB7X/b9S9q
GuEzh236KN56+xnTkC4IFu/kylvbaN0kYBVF+RtC04Ez0ksg6MbybKRtmDmHeRib
/SpTRGM930/jjjMaGTIph9MrQxEWhDB/iCHPM6Ghyi8W3lptws2y5izW1g1TAgMB
AAGjgYYwgYMwDgYDVR0PAQH/BAQDAgKEMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggr
BgEFBQcDAjASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBQT2Q46hkQnjZ7G
BBgMrpZIv0FemjAfBgNVHSMEGDAWgBQT2Q46hkQnjZ7GBBgMrpZIv0FemjANBgkq
hkiG9w0BAQsFAAOCAQEATB+YL20s8OLBPyl5OKwdNDqaMpAK0voZW2TVS0Qo6Igk
72mq0kpdHypdJjYhMK2e49/NZD3s2KCJWLzV7WVZ2LHy0MXzxZKIzQYbzg/GMbn1
zYp3aj4TRiJaoPaokupq07/qYDUyg2Raq51ffoHSH6bmQG+6RplRmLU2HCuKYXjZ
0AeuGEEanqV0jlxw3ngcGF+sPj+aXnmMHQJ1V/8E5d2kcbbIFfxNLlkhE2fgkBoG
cip9mzyHK6hoKgRLNuyadurvI6sJ53lyBapCQkYk2TvCrHNKh4UUXIPKYeIpEb7a
mdzJvUDlumspdeiX1InWOc15LrZndFcoyN0PIL+fLg==
-----END CERTIFICATE-----
  EOF
}

variable "ca_key" {
  default =<<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAmuBggPR0hBnydZfXPnHAPA+sSG9ixA+7nfduGrfkLNuGRl7r
NxlU0ilFcXriBEpv39dCNVFtUPJJ/ZREo1jRpLPrjrxP6vCgsYMMNhy9qP4Jk593
wE0PkAnsUYol3DZT3s8wDLsmSRE0ylEg4f1D1DIjXSnr6h6/O9OgajFEUna9OkGf
kJDr9/hY4iQwm5ccerdj0jDiPkWRI2JRQe1/2/UvahrhM4dt+ijeevsZ05AuCBbv
5Mpb22jdJGAVRfkbQtOBM9JLIOjG8mykbZg5h3kYm/0qU0RjPd9P444zGhkyKYfT
K0MRFoQwf4ghzzOhocovFt5abcLNsuYs1tYNUwIDAQABAoIBAGiWd3T+ICUJZKu2
s1tu87Nbnit4VMk0Gq3tZoRShJsqT/37oXoe+CHITyX4JuNg5TXTJtncuCa+x+qf
ks6Ab2p7Oeq1Dn8IqmvVpIxyUj3p98uiF/tbztOlb9oMoc6ZPYAsiDVAuPUE0pKB
wOP75S9KAImsgq0iwF+FZUHxLUNF8UfCtEGrWd7nY1MNwF5vZuu5kjT9u3GvAt+s
7guMmNuO/SRwA/OhfTFRtwXUk8o+cJDBnDkmzj+U3dX/Z6eGYS2Jhi+Jo/z4+4LQ
vkMB9Xtgtq9H3q4jbLjhc3mMCf55PLLLHkH5v3Bd3BezeLwuFYm2JOIK9WNuhQQ+
xEZ4omkCgYEAxVS/6m837zKWfhnU9vbMs6rRniLgICn6mNsdPsI9ApP6o4Jk7dTu
XbH6+IxLR+0ipTN2dOcj7RYNnVT6rgb5SosEMrz+UDKOgPeTdmOKhi5JTPp9v2Mt
AhmdtWpf98jyu6HeHL2nTRyiMLRYE/2f7BghyJ9ZRMn/RpxeEXjA+V8CgYEAyOxT
mZsfe0ktnsXIADuFkrOzmUfSR6CCfzATJ5ASqOf7VEG7fWeUGgMtgjZG28TySxNC
YUfSwZb0Dxs3cUhM5l6WU3Ym+7VadiFe93iBWdgwESLczpjfpE7qSTDoShlUWYDv
zsBBgOBfNKAIaTbRB/jqriJrtjBq7O3wIuFLzI0CgYAHnifyguyj3U4V/CVOi2SH
oxaIhkwksbos4HiWjaURTmkkmsoOrGOvVkmcAr59PlhSDFSMWsf2RR2tbzRmN3q0
N/2nf8hJjEoYDHay4VDdsTe/MwRbuRZpuFdwQ3UE+cr1F2Cdt2yX+3z/aFbmHqpn
0N6tAgnOMAYc0biH8CNy/QKBgQCYgUizPtsWaOUHrnewNX2dbGjV333sgBiNEaB4
VxLSwcIyofH9rbDsTZ0tSKVgCo0eDvBDhpCiAEIfdTkP8yDrer//eZ79TxnqsEm0
7PLBjyZs21leNwsJXBzYkRa/p5oulX9wHt2ZRLT+7Ll1ovXmZzk6E0ZOc1G1pKSw
1PEDwQKBgCY+zLSyWs/M3oI9y9aMfOuQFHgRZxDcSG7ce2xGUAwsUKJwtq4XylQZ
QkABF4fWIeEs0h0tOt+yowF1PU7Q4AH1MKQZCoqKP1Y62T/zGRr59huDZlN+Z3tf
OIotPP8nCOs8Sqq76VHaFxLLIrkCowq+wjtLzNgRRGbkDwohd//l
-----END RSA PRIVATE KEY-----
  EOF
}
