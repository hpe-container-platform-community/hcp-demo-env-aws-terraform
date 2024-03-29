output "private_ip" {
  value = var.rdp_server_enabled && length(aws_instance.rdp_server) > 0 ? aws_instance.rdp_server[0].private_ip : null
}

locals {
  rdp_created = var.rdp_server_enabled && length(aws_instance.rdp_server) > 0
}

output "public_ip" {
  value = local.rdp_created ? (var.create_eip ? aws_eip.rdp_server[0].public_ip : aws_instance.rdp_server[0].public_ip) : null
}

output "instance_id" {
  value = var.rdp_server_enabled && length(aws_instance.rdp_server) > 0  ? aws_instance.rdp_server[0].id : null
}

output "instance_arn" {
  value = var.rdp_server_enabled && length(aws_instance.rdp_server) > 0  ? aws_instance.rdp_server[0].arn : null
}

output "ssh_command" {
  value = var.rdp_server_enabled && length(aws_instance.rdp_server) > 0  ? "ssh -o StrictHostKeyChecking=no -i \"${var.ssh_prv_key_path}\" centos@${aws_instance.rdp_server[0].public_ip}" : "rdp server not enabled"
}

output "enc_administrator_password" {
  value = var.rdp_server_enabled && length(aws_instance.rdp_server) > 0  ? aws_instance.rdp_server[0].password_data : null
}
output "network_interface_id" {
  value = var.rdp_server_enabled && length(aws_instance.rdp_server) > 0  ? aws_instance.rdp_server[0].primary_network_interface_id : null
}