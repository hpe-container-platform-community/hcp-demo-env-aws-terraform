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
variable "vpc_cidr_block" {
    type = string
}
variable "subnet_cidr_block" {
    type = string
}
variable "allow_ssh_from_world" {
    type = bool
}
variable "allow_rdp_from_world" {
    type = bool
}