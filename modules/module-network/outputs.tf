output "security_group_main_id" {
  value = aws_security_group.main.id
}

output "security_group_allow_ssh_from_world_id" {
  value = aws_security_group.allow_ssh_from_world.id
}

output "security_group_allow_rdp_from_world_id" {
  value = aws_security_group.allow_rdp_from_world.id
}

output "security_group_allow_all_from_client_ip" {
  value = aws_security_group.allow_all_from_specified_ips.id
}

output "security_group_allow_all_from_client_ip_arn" {
  value = aws_security_group.allow_all_from_specified_ips.arn
}

output "vpc_main_id" {
  value = aws_vpc.main.id
}

output "vpc_main_arn" {
  value = aws_vpc.main.arn
}

output "route_main_id" {
  value = aws_route_table.main.id
}

output "subnet_main_id" {
  value = aws_subnet.main.id
}

output "network_acl_id" {
  value = aws_network_acl.main.id
}

output "network_acl_arn" {
  value = aws_network_acl.main.arn
}

output "sg_allow_all_from_specified_ips" {
  value = aws_security_group.allow_all_from_specified_ips.id
}