
resource "local_file" "ca-cert" {
  filename = "${path.module}/generated/ca-cert.pem"
  content =  var.ca_cert
}

resource "local_file" "ca-key" {
  filename = "${path.module}/generated/ca-key.pem"
  content =  var.ca_key
}


//////////////////// Utility scripts  /////////////////////

/// instance start/stop/status

locals {
  instance_ids = "${module.nfs_server.instance_id != null ? module.nfs_server.instance_id : ""} ${module.ad_server.instance_id != null ? module.ad_server.instance_id : ""} ${module.rdp_server.instance_id != null ? module.rdp_server.instance_id : ""} ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", aws_instance.workers.*.id)}"
}

resource "local_file" "cli_stop_ec2_instances" {
  filename = "${path.module}/generated/cli_stop_ec2_instances.sh"
  content =  <<-EOF
    aws --region ${var.region} --profile ${var.profile} ec2 stop-instances --instance-ids ${local.instance_ids} 
  EOF
}

resource "local_file" "cli_start_ec2_instances" {
  filename = "${path.module}/generated/cli_start_ec2_instances.sh"
  content = <<-EOF
    aws --region ${var.region} --profile ${var.profile} ec2 start-instances --instance-ids ${local.instance_ids} 
  EOF
}

resource "local_file" "cli_running_ec2_instances" {
  filename = "${path.module}/generated/cli_running_ec2_instances.sh"
  content = <<-EOF
    echo Running:  $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${local.instance_ids} --filter Name=instance-state-name,Values=running --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Starting: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${local.instance_ids} --filter Name=instance-state-name,Values=pending --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Stopping: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${local.instance_ids} --filter Name=instance-state-name,Values=stopping --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Stopped:  $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${local.instance_ids} --filter Name=instance-state-name,Values=stopped --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
  EOF  
}


resource "local_file" "ssh_controller" {
  filename = "${path.module}/generated/ssh_controller.sh"
  content = <<-EOF
     #!/bin/bash
     ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_eip.controller.public_ip} "$@"
  EOF
}

resource "local_file" "mcs_credentials" {
  filename = "${path.module}/generated/mcs_credentials.sh"
  content = <<-EOF
     #!/bin/bash
     echo
     echo [MAPR MCS Credentials] admin:$(ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_eip.controller.public_ip} "cat /opt/bluedata/mapr/conf/mapr-admin-pass")
     echo
  EOF
}

resource "local_file" "ssh_gateway" {
  filename = "${path.module}/generated/ssh_gateway.sh"
  content = <<-EOF
     #!/bin/bash
     ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_eip.gateway.public_ip} "$@"
  EOF
}