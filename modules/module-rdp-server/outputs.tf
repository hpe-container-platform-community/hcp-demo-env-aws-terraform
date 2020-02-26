output "private_ip" {
  value = aws_instance.rdp_server[0].private_ip
}

output "public_ip" {
  value = aws_instance.rdp_server[0].public_ip
}

output "instance_id" {
  value = aws_instance.rdp_server.*.id
}

output "ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.rdp_server[0].public_ip}"
}