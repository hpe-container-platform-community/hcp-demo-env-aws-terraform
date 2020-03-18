variable "project_id" { 
    type = string
}
variable "user" {
    type = string
 }
variable "ssh_prv_key_path" {
    type = string
}
variable "rdp_ec2_ami" { 
    type = string
}
variable "rdp_instance_type" { 
    type = string
}
variable "rdp_server_enabled" { 
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
variable "az" {
    type = string
}