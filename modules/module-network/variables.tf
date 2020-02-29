variable "project_id" { 
    type = string
}
variable "user" {
    type = string
}
variable "aws_zone_id" {
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