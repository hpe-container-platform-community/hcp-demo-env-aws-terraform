variable "project_id" { 
    type = string
}
variable "user" {
    type = string
 }
variable "ssh_prv_key_path" {
    type = string
}
variable "ad_ec2_ami" { 
    type = string
}
variable "ad_instance_type" { 
    type = string
}
variable "ad_server_enabled" { 
    type = bool
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
variable "deployment_uuid" { 
    type = string
}
variable "ad_admin_group" {
    type = string
}
variable "ad_member_group" {
    type = string
}
