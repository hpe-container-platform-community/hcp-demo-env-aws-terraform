//////////////////// Utility scripts  /////////////////////

/// instance start/stop/status

resource "local_file" "cli_stop_ec2_instances" {
  filename = "${path.module}/generated/cli_stop_ec2_instances.sh"
  content =  <<-EOF
    aws --region ${var.region} --profile ${var.profile} ec2 stop-instances --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", module.rdp_server.instance_id)} ${join(" ", aws_instance.workers.*.id)} 
  EOF
}

resource "local_file" "cli_start_ec2_instances" {
  filename = "${path.module}/generated/cli_start_ec2_instances.sh"
  content = <<-EOF
    aws --region ${var.region} --profile ${var.profile} ec2 start-instances --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", module.rdp_server.instance_id)} ${join(" ", aws_instance.workers.*.id)}
  EOF
}

resource "local_file" "cli_running_ec2_instances" {
  filename = "${path.module}/generated/cli_running_ec2_instances.sh"
  content = <<-EOF
    echo Running: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", module.rdp_server.instance_id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=running --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Starting: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", module.rdp_server.instance_id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=pending --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Stopping: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", module.rdp_server.instance_id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=stopping --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Stopped: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", module.rdp_server.instance_id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=stopped --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
  EOF  
}


resource "local_file" "ssh_controller" {
  filename = "${path.module}/generated/ssh_controller.sh"
  content = <<-EOF
     #!/bin/bash
     ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_eip.controller.public_ip} "$@"
  EOF
}

resource "local_file" "ssh_gateway" {
  filename = "${path.module}/generated/ssh_gateway.sh"
  content = <<-EOF
     #!/bin/bash
     ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_eip.gateway.public_ip} "$@"
  EOF
}
