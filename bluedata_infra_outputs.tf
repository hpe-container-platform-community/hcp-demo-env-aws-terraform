output "project_dir" {
  value = "${abspath(path.module)}"
}

output "aws_region" {
  value = "${var.region}"
}

output "subnet_cidr_block" {
  value = "${var.subnet_cidr_block}"
}

output "vpc_cidr_block" {
  value = "${var.vpc_cidr_block}"
}

output "deployment_uuid" {
  value = "${random_uuid.deployment_uuid.result}"
}

output "selinux_disabled" {
  value = "${var.selinux_disabled}"
}

output "ssh_pub_key_path" {
  value = "${var.ssh_pub_key_path}"
}

output "ssh_prv_key_path" {
  value = "${var.ssh_prv_key_path}"
}

output "install_with_ssl" {
  value = "${var.install_with_ssl}"
}

output "ca_cert" {
  value = "${var.ca_cert}"
}

output "ca_key" {
  value = "${var.ca_key}"
}

output "epic_dl_url" {
  value = "${var.epic_dl_url}"
}

output "epid_dl_url_needs_presign" {
  value = "${var.epid_dl_url_needs_presign}"
}

output "epic_dl_url_presign_options" {
  value = "${var.epic_dl_url_presign_options}"
}

output "client_cidr_block" {
 value = "${var.client_cidr_block}"
}

output "create_eip_controller" {
  value = "${var.create_eip_controller}"
}

output "create_eip_gateway" {
  value = "${var.create_eip_gateway}"
}

output "create_eip_rdp_linux_server" {
  value = "${var.create_eip_rdp_linux_server}"
}

output "gateway_private_ip" {
  value = "${module.gateway.private_ip}"
}
output "gateway_private_dns" {
  value = "${module.gateway.private_dns}"
}
output "gateway_public_ip" {
  value = "${module.gateway.public_ip}"
}
output "gateway_public_dns" {
  value = "${module.gateway.public_dns}"
}

output "controller_public_ip" {
  value = "${module.controller.public_ip}"
}

output "controller_public_url" {
  value = "https://${module.controller.public_ip}"
}

output "controller_private_ip" {
  value = "${module.controller.private_ip}"
}

output "controller_public_dns" {
  value = "${module.controller.public_dns}"
}

output "controller_private_dns" {
  value = "${module.controller.private_dns}"
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

output "mapr_hosts_public_ip" {
  value = ["${aws_instance.mapr_hosts.*.public_ip}"]
}
output "mapr_hosts_public_dns" {
  value = ["${aws_instance.mapr_hosts.*.public_dns}"]
}
output "mapr_hosts_private_ip" {
  value = ["${aws_instance.mapr_hosts.*.private_ip}"]
}
output "mapr_hosts_private_dns" {
  value = ["${aws_instance.mapr_hosts.*.private_dns}"]
}

output "mapr_count" {
  value = ["${var.mapr_count}"]
}


output "controller_ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i \"${var.ssh_prv_key_path}\" centos@${module.controller.public_ip}"
}

output "gateway_ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i \"${var.ssh_prv_key_path}\" centos@${module.gateway.public_ip}"
}

output "workers_ssh" {
  value = {
    for instance in aws_instance.workers:
    instance.private_ip => "ssh -o StrictHostKeyChecking=no -i '${var.ssh_prv_key_path}' centos@${instance.public_ip}" 
  }
}

output "mapr_hosts_ssh" {
  value = {
    for instance in aws_instance.mapr_hosts:
    instance.private_ip => "ssh -o StrictHostKeyChecking=no -i '${var.ssh_prv_key_path}' centos@${instance.public_ip}" 
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

output "ad_server_public_ip" {
  value = module.ad_server.public_ip
}

output "ad_server_ssh_command" {
  value = module.ad_server.ssh_command
}

output "ad_server_enabled" {
  value = var.ad_server_enabled
}

// RDP Server Output

output "rdp_server_enabled" {
  value = var.rdp_server_enabled
}

output "rdp_server_private_ip" {
  value = var.rdp_server_operating_system == "WINDOWS" ? module.rdp_server.private_ip : module.rdp_server_linux.private_ip
}

output "rdp_server_public_ip" {
  value = var.rdp_server_operating_system == "WINDOWS" ? module.rdp_server.public_ip : module.rdp_server_linux.public_ip
}

output "rdp_server_instance_id" {
  value = var.rdp_server_operating_system == "WINDOWS" ? module.rdp_server.instance_id : module.rdp_server_linux.instance_id
}

output "rdp_server_operating_system" {
  value = var.rdp_server_operating_system
}

output "softether_rdp_ip" {
  value = var.softether_rdp_ip
}
