
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

    echo "*******************************************************************************"
    echo "IMPORTANT: You need to run the following command to update changed IP addresses"
    echo "           ./bin/terraform_appy.sh"
    echo "*******************************************************************************"
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

resource "local_file" "ssh_gateway" {
  filename = "${path.module}/generated/ssh_gateway.sh"
  content = <<-EOF
     #!/bin/bash
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@${module.gateway.public_ip} "$@"
  EOF
}

resource "local_file" "ssh_worker" {
  count = var.worker_count

  filename = "${path.module}/generated/ssh_worker_${count.index + 1}.sh"
  content = <<-EOF
     #!/bin/bash
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@${aws_instance.workers[count.index].public_ip} "$@"
  EOF
}

resource "local_file" "ssh_workers" {
  count = var.worker_count
  filename = "${path.module}/generated/ssh_worker_all.sh"
  content = <<-EOF
     #!/bin/bash

     if [[ $# -lt 1 ]]
     then
        echo "You must provide at least one command, e.g."
        echo "./generated/ssh_worker_all.sh CMD1 CMD2 CMDn"
        exit 1
     fi

     WORKERS='${join(" ", aws_instance.workers.*.public_ip)}'
     for WORKER in $WORKERS;
     do
      ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$WORKER "$@"
     done
  EOF
}

resource "local_file" "ssh_all" {
  count = var.worker_count
  filename = "${path.module}/generated/ssh_all.sh"
  content = <<-EOF
     #!/bin/bash

     if [[ $# -lt 1 ]]
     then
        echo "You must provide at least one command, e.g."
        echo "./generated/ssh_worker_all.sh CMD1 CMD2 CMDn"
        exit 1
     fi

     HOSTS='${module.controller.public_ip} ${module.gateway.public_ip} ${join(" ", aws_instance.workers.*.public_ip)}'
     for HOST in $HOSTS;
     do
        ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$HOST "$@"
     done
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

    if grep -q 'OPENSSH' "${var.ssh_prv_key_path}"
    then
      echo "***** ERROR ******"
      echo "Found OPENSSH key but need RSA key at ${var.ssh_prv_key_path}"
      echo "You can convert with:"
      echo "$ ssh-keygen -p -N '' -m pem -f '${var.ssh_prv_key_path}'"
      echo "******************"
      exit 1
    fi

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

resource "local_file" "whatismyip" {
  filename = "${path.module}/generated/whatismyip.sh"

  content = <<-EOF
     #!/bin/bash
     echo $(curl -s http://ifconfig.me/ip)/32
  EOF
}