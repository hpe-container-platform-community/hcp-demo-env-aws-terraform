output "selinux_disabled" {
  value = "${var.selinux_disabled}"
}

output "ssh_pub_key_path" {
  value = "${var.ssh_pub_key_path}"
}

output "ssh_prv_key_path" {
  value = "${var.ssh_prv_key_path}"
}

output "epic_dl_url" {
  value = "${var.epic_dl_url}"
}

output "client_cidr_block" {
 value = "${var.client_cidr_block}"
}

output "gateway_private_ip" {
  value = "${aws_instance.gateway.private_ip}"
}
output "gateway_private_dns" {
  value = "${aws_instance.gateway.private_dns}"
}
output "gateway_public_ip" {
  value = "${aws_eip.gateway.public_ip}"
}
output "gateway_public_dns" {
  value = "${aws_eip.gateway.public_dns}"
}

output "controller_public_ip" {
  value = "${aws_eip.controller.public_ip}"
}

output "controller_private_ip" {
  value = "${aws_instance.controller.private_ip}"
}

output "workers_public_ip" {
  value = ["${aws_instance.workers.*.public_ip}"]
}
output "workers_public_dns" {
  value = ["${aws_instance.workers.*.public_dns}"]
}
output "workers_private_ip" {
  value = ["${aws_instance.workers.*.private_ip}"]
}
output "workers_private_dns" {
  value = ["${aws_instance.workers.*.private_dns}"]
}

output "controller_ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_eip.controller.public_ip}"
}

output "gateway_ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_eip.gateway.public_ip}"
}

output "workers_ssh" {
  value = {
    for instance in aws_instance.workers:
    instance.id => "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${instance.public_ip}" 
  }
}

// NFS Server Output

output "nfs_server_private_ip" {
  value = module.nfs_server.private_ip
}

output "nfs_server_folder" {
  value = module.nfs_server.nfs_folder
}

output "nfs_server_ssh_command" {
  value = module.nfs_server.ssh_command
}

// AD Server Output

output "ad_server_private_ip" {
  value = module.ad_server.private_ip
}

output "ad_server_ssh_command" {
  value = module.ad_server.ssh_command
}

// RDP Server Output

output "rdp_server_private_ip" {
  value = module.rdp_server.private_ip
}

output "rdp_server_public_ip" {
  value = module.rdp_server.public_ip
}

output "rdp_server_ssh_command" {
  value = module.rdp_server.ssh_command
}