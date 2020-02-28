output "private_ip" {
  value = var.rdp_server_enabled ? aws_instance.rdp_server[0].private_ip : null
}

output "public_ip" {
  value = var.rdp_server_enabled ? aws_instance.rdp_server[0].public_ip : null
}

output "instance_id" {
  value = var.rdp_server_enabled ? aws_instance.rdp_server[0].id : null
}

output "ssh_command" {
  value = var.rdp_server_enabled ? "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.rdp_server[0].public_ip}" : "rdp server not enabled"
}