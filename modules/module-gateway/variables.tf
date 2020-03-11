variable "project_id" { 
    type = string
}
variable "user" {
    type = string
}
variable "aws_zone_id" {
    type = string
}
variable "az" {
    type = string
}
variable "client_cidr_block" {
    type = string
}
variable "additional_client_ip_list" {
    type = list
}
variable "vpc_cidr_block" {
    type = string
}
variable "subnet_cidr_block" {
    type = string
}
variable "key_name" { 
    type = string
}
variable "security_group_ids" {
    type = list
}
variable "subnet_id" { 
    type = string
}
variable "ec2_ami" { 
    type = string
}
variable "gtw_instance_type" {
    type = string
}
variable "ssh_prv_key_path" {
    type = string
}
variable "create_eip" {
    type = bool
}