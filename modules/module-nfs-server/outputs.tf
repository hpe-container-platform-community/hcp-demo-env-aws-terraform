output "private_ip" {
  value = var.nfs_server_enabled ? aws_instance.nfs_server[0].private_ip : null
}

output "nfs_folder" {
  value = var.nfs_server_enabled ? "/nfsroot" : "nfs server not enabled"
}

output "instance_id" {
  value = var.nfs_server_enabled ? aws_instance.nfs_server[0].id : null
}

output "instance_arn" {
  value = var.nfs_server_enabled ? aws_instance.nfs_server[0].arn : null
}

output "ssh_command" {
  value = var.nfs_server_enabled ? "ssh -o StrictHostKeyChecking=no -i \"${var.ssh_prv_key_path}\" centos@${aws_instance.nfs_server[0].public_ip}" : "nfs server not enabled"
}