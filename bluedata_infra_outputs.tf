output "project_dir" {
  value = abspath(path.module)
}

output "additional_client_ip_list" {
  value = var.additional_client_ip_list
}

output "user" {
  value = local.user
}

output "project_id" {
  value = var.project_id
}

output "aws_profile" {
  value = var.profile
}

output "aws_region" {
  value = var.region
}

output "subnet_cidr_block" {
  value = var.subnet_cidr_block
}

output "vpc_cidr_block" {
  value = var.vpc_cidr_block
}

output "deployment_uuid" {
  value = random_uuid.deployment_uuid.result
}

output "selinux_disabled" {
  value = var.selinux_disabled
}

output "ssh_pub_key_path" {
  value = var.ssh_pub_key_path
}

output "ssh_prv_key_path" {
  value = var.ssh_prv_key_path
}

output "install_with_ssl" {
  value = var.install_with_ssl
}

output "ca_cert" {
  value = data.local_file.ca_cert.content
}

output "ca_key" {
  value = data.local_file.ca_key.content
}

output "epic_dl_url" {
  value = var.epic_dl_url
}

output "epid_dl_url_needs_presign" {
  value = var.epid_dl_url_needs_presign
}

output "epic_dl_url_presign_options" {
  value = var.epic_dl_url_presign_options
}

output "epic_options" {
  value = var.epic_options
}

output "client_cidr_block" {
 value = var.client_cidr_block
}

output "create_eip_controller" {
  value = var.create_eip_controller
}

output "create_eip_gateway" {
  value = var.create_eip_gateway
}

output "create_eip_rdp_linux_server" {
  value = var.create_eip_rdp_linux_server
}

output "create_eks_cluster" {
  value = var.create_eks_cluster
}

//// Gateway

output "gateway_instance_id" {
  value = module.gateway.id
}
output "gateway_private_ip" {
  value = module.gateway.private_ip
}
output "gateway_private_dns" {
  value = module.gateway.private_dns
}
output "gateway_public_ip" {
  value = module.gateway.public_ip
}
output "gateway_public_dns" {
  value = module.gateway.public_dns
}

//// Controllers

output "controller_instance_id" {
  value = module.controller.id
}

output "controller_public_ip" {
  value = module.controller.public_ip
}

output "controller_public_url" {
  value = "https://${module.controller.public_ip}"
}

output "controller_private_ip" {
  value = module.controller.private_ip
}

output "controller_public_dns" {
  value = module.controller.public_dns
}

output "controller_private_dns" {
  value = module.controller.private_dns
}

/// workers

output "workers_instance_id" {
  value = [aws_instance.workers.*.id]
}
output "workers_instance_arn" {
  value = [aws_instance.workers.*.arn]
}
output "workers_public_ip" {
  value = [aws_instance.workers.*.public_ip]
}
output "workers_public_dns" {
  value = [aws_instance.workers.*.public_dns]
}
output "workers_private_ip" {
  value = [aws_instance.workers.*.private_ip]
}
output "workers_private_dns" {
  value = [aws_instance.workers.*.private_dns]
}

output "worker_count" {
  value = [var.worker_count]
}

output "embedded_df" {
  value = var.embedded_df
}

/// GPU workers

output "workers_gpu_instance_id" {
  value = [aws_instance.workers_gpu.*.id]
}
output "workers_gpu_instance_arn" {
  value = [aws_instance.workers_gpu.*.arn]
}
output "workers_gpu_public_ip" {
  value = [aws_instance.workers_gpu.*.public_ip]
}
output "workers_gpu_public_dns" {
  value = [aws_instance.workers_gpu.*.public_dns]
}
output "workers_gpu_private_ip" {
  value = [aws_instance.workers_gpu.*.private_ip]
}
output "workers_gpu_private_dns" {
  value = [aws_instance.workers_gpu.*.private_dns]
}

output "gpu_worker_count" {
  value = [var.gpu_worker_count]
}

//// MAPR Cluster 1

output "mapr_cluster_1_hosts_instance_id" {
  value = [aws_instance.mapr_cluster_1_hosts.*.id]
}
output "mapr_cluster_1_hosts_instance_arn" {
  value = [aws_instance.mapr_cluster_1_hosts.*.arn]
}
output "mapr_cluster_1_hosts_public_ip" {
  value = [aws_instance.mapr_cluster_1_hosts.*.public_ip]
}
output "mapr_cluster_1_hosts_public_dns" {
  value = [aws_instance.mapr_cluster_1_hosts.*.public_dns]
}
output "mapr_cluster_1_hosts_private_ip" {
  value = [aws_instance.mapr_cluster_1_hosts.*.private_ip]
}
output "mapr_cluster_1_hosts_private_ip_flat" {
  value = join("\n", aws_instance.mapr_cluster_1_hosts.*.private_ip)
}
output "mapr_cluster_1_hosts_public_ip_flat" {
  value = join("\n", aws_instance.mapr_cluster_1_hosts.*.public_ip)
}
output "mapr_cluster_1_hosts_private_dns" {
  value = [aws_instance.mapr_cluster_1_hosts.*.private_dns]
}
output "mapr_cluster_1_count" {
  value = [var.mapr_cluster_1_count]
}
output "mapr_cluster_1_name" {
  value = [var.mapr_cluster_1_name]
}

/// MAPR Cluster 2

output "mapr_cluster_2_hosts_instance_id" {
  value = [aws_instance.mapr_cluster_2_hosts.*.id]
}
output "mapr_cluster_2_hosts_instance_arn" {
  value = [aws_instance.mapr_cluster_2_hosts.*.arn]
}
output "mapr_cluster_2_hosts_public_ip" {
  value = [aws_instance.mapr_cluster_2_hosts.*.public_ip]
}
output "mapr_cluster_2_hosts_public_dns" {
  value = [aws_instance.mapr_cluster_2_hosts.*.public_dns]
}
output "mapr_cluster_2_hosts_private_ip" {
  value = [aws_instance.mapr_cluster_2_hosts.*.private_ip]
}
output "mapr_cluster_2_hosts_private_ip_flat" {
  value = join("\n", aws_instance.mapr_cluster_2_hosts.*.private_ip)
}
output "mapr_cluster_2_hosts_public_ip_flat" {
  value = join("\n", aws_instance.mapr_cluster_2_hosts.*.public_ip)
}
output "mapr_cluster_2_hosts_private_dns" {
  value = [aws_instance.mapr_cluster_2_hosts.*.private_dns]
}
output "mapr_cluster_2_count" {
  value = [var.mapr_cluster_2_count]
}
output "mapr_cluster_2_name" {
  value = [var.mapr_cluster_2_name]
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

output "mapr_cluster_1_hosts_ssh" {
  value = {
    for instance in aws_instance.mapr_cluster_1_hosts:
    instance.private_ip => "ssh -o StrictHostKeyChecking=no -i '${var.ssh_prv_key_path}' centos@${instance.public_ip}" 
  }
}

// NFS Server Output

output "nfs_server_enabled" {
  value = var.nfs_server_enabled
}

output "nfs_server_instance_id" {
  value = module.nfs_server.instance_id
}

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

output "ad_server_instance_id" {
  value = module.ad_server.instance_id
}

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

output "ad_admin_group" {
  value = var.ad_admin_group
}

output "ad_member_group" {
  value = var.ad_member_group
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
