output "ad_server_private_ip" {
  value = "${aws_instance.ad_server[0].private_ip}"
}

output "ad_server_ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.ad_server[0].public_ip}"
}

output "instance_id" {
  value = aws_instance.ad_server.*.id
}