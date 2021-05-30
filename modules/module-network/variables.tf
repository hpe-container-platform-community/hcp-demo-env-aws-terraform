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
variable "dns_zone_name" {
    type = string
}
variable "controller_private_ip" {
    type = string
}
variable "gateway_private_ip" {
    type = string
}
variable "workers_private_ip" {
    type = list
}
variable "ad_server_enabled" {
    type = bool
}
variable "ad_private_ip" {
    type = string
}
variable "rdp_network_interface_id" {
    type = string
}
variable "rdp_private_ip" {
    type = string
}
variable "rdp_linux_server_enabled" {
    type = string
}
variable "softether_cidr_block" {
    type = string
}
variable "deployment_uuid" { 
    type = string
}