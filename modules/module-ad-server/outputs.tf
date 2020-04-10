output "private_ip" {
  value = var.ad_server_enabled ? aws_instance.ad_server[0].private_ip : null
}

output "public_ip" {
  value = var.ad_server_enabled ? aws_instance.ad_server[0].public_ip : null
}

output "ssh_command" {
  value = var.ad_server_enabled ? "ssh -o StrictHostKeyChecking=no -i \"${var.ssh_prv_key_path}\" centos@${aws_instance.ad_server[0].public_ip}" : "ad server not enabled"
}

output "instance_id" {
  value = var.ad_server_enabled ? aws_instance.ad_server[0].id : null
}