
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
  instance_ids = "${module.nfs_server.instance_id != null ? module.nfs_server.instance_id : ""} ${module.ad_server.instance_id != null ? module.ad_server.instance_id : ""} ${module.rdp_server.instance_id != null ? module.rdp_server.instance_id : ""} ${module.controller.id} ${module.gateway.id} ${join(" ", aws_instance.workers.*.id)}"
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
    #!/bin/bash
    aws --region ${var.region} --profile ${var.profile} ec2 start-instances --instance-ids ${local.instance_ids} 

    terraform output -json > "${path.module}generated/output.json"
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
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@${module.controller.public_ip} "$@"
  EOF
}

resource "local_file" "mcs_credentials" {
  filename = "${path.module}/generated/mcs_credentials.sh"
  content = <<-EOF
     #!/bin/bash
     echo 
     echo ==== MCS Credentials ====
     echo 
     echo IP Addr:  ${module.controller.public_ip}
     echo Username: admin
     echo Password: $(ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@${module.controller.public_ip} "cat /opt/bluedata/mapr/conf/mapr-admin-pass")
     echo
  EOF
}

resource "local_file" "ssh_gateway" {
  filename = "${path.module}/generated/ssh_gateway.sh"
  content = <<-EOF
     #!/bin/bash
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@${module.gateway.public_ip} "$@"
  EOF
}

resource "local_file" "restart_auth_proxy" {
  filename = "${path.module}/generated/restart_auth_proxy.sh"
  content = <<-EOF
     #!/bin/bash
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@${module.controller.public_ip} "docker restart epic-auth-proxy-k8s-id-1"
  EOF
}

resource "local_file" "platform_id" {
  filename = "${path.module}/generated/platform_id.sh"
  content = <<-EOF
     #!/bin/bash
     curl -s -k https://${module.controller.public_ip}:8080/api/v1/license | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["uuid"])'
  EOF
}

resource "local_file" "rdp_credentials" {
  filename = "${path.module}/generated/rdp_credentials.sh"
  count = var.rdp_server_enabled == true ? 1 : 0
  content = <<-EOF
     #!/bin/bash

     # TODO: check for -----BEGIN OPENSSH PRIVATE KEY-----
     #       suggest fix: ssh-keygen -p -N "" -m pem -f /path/to/key

     echo 
     echo ==== RDP Credentials ====
     echo 
     echo IP Addr:  ${module.rdp_server.public_ip}
     echo URL:      "rdp://full%20address=s:${module.rdp_server.public_ip}:3389&username=s:Administrator"
     echo Username: Administrator
     echo -n "Password: "
     aws --region ${var.region} \
        --profile ${var.profile} \
        ec2 get-password-data \
        "--instance-id=${module.rdp_server.instance_id}" \
        --query 'PasswordData' | sed 's/\"\\r\\n//' | sed 's/\\r\\n\"//' | base64 -D | openssl rsautl -inkey "${var.ssh_prv_key_path}" -decrypt
      echo
      echo
  EOF
}
