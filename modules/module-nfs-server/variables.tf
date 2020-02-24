variable "project_id" { 
    type = string
}
variable "user" {
    type = string
 }
variable "ssh_prv_key_path" {
    type = string
}
variable "nfs_ec2_ami" { 
    type = string
}
variable "nfs_instance_type" { 
    type = string
    default = "t2.small" 
}
variable "nfs_server_enabled" { 
    type = string
    default = false
}
variable "key_name" { 
    type = string
}
variable "vpc_security_group_ids" { 
    type = list
}
variable "subnet_id" { 
    type = string
}