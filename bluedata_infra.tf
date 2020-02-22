// Usage: terraform <action> -var-file="bluedata_infra.tfvars"

variable "profile" { default = "default" }
variable "region" { }
variable "az" { }
variable "project_id" { }
variable "user" { }
variable "client_cidr_block" {  }
variable "check_client_ip" { default = "true" }
variable "vpc_cidr_block" { }
variable "subnet_cidr_block" { }
variable "ec2_ami" { }
variable "ssh_prv_key_path" {}
variable "ssh_pub_key_path" {}
variable "worker_count" { default = 3 }

variable "gtw_instance_type" { default = "m4.2xlarge" }
variable "ctr_instance_type" { default = "m4.2xlarge" }
variable "wkr_instance_type" { default = "m4.2xlarge" }
variable "nfs_instance_type" { default = "t2.small" }
variable "ad_instance_type" { default = "t2.small" }

variable "epic_dl_url" { }
variable "selinux_disabled" { default = false }

variable "ec2_shutdown_schedule_expression" { default = "cron(0 20 ? * MON-FRI *)" } # UTC time
variable "ec2_shutdown_schedule_is_enabled" { default = false }

variable "nfs_server_enabled" { default = false }
variable "ad_server_enabled" { default = true }

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

/******************* elastic ips ********************/

resource "aws_eip" "controller" {
  vpc = true

  tags = {
    Name = "${var.project_id}-controller"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_eip" "gateway" {
  vpc = true

  tags = {
    Name = "${var.project_id}-gateway"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

/******************* ssh pub key content ********************/

data "local_file" "ssh_pub_key" {
    filename = "${var.ssh_pub_key_path}"
}

/******************* verify client ip ********************/

data "external" "example1" {
 program = [ "python3", "${path.module}/verify_client_ip.py", "${var.client_cidr_block}", "${var.check_client_ip}" ]
}

output "client_cidr_block" {
 value = "${var.client_cidr_block}"
}

/******************* setup region and az ********************/

provider "aws" {
  profile = "${var.profile}"
  region  = "${var.region}"
}

data "aws_availability_zone" "main" {
  name = "${var.az}"
}

/******************* VPC ********************/

resource "aws_vpc" "main" {
  cidr_block  = "${var.vpc_cidr_block}"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_id}-vpc"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

/******************* Network ACL ********************/

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.main.default_network_acl_id}"
  subnet_ids = [ "${aws_subnet.main.id}" ]

  # allow client machine to have full access to all hosts
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "${var.client_cidr_block}"
    from_port  = 0
    to_port    = 0
  }


  # allow internet access from instances 
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # allow response traffic from hosts to internet
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  tags = {
    Name = "${var.project_id}-default-network-acl"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

/******************* Security Group ********************/

resource "aws_default_security_group" "main" {
  vpc_id      = "${aws_vpc.main.id}"

  # allow client machine to have full access
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "${var.client_cidr_block}" ]
  }

  # allow full host to host access for all hosts within this security group
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_id}-default-security-group"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

/******************* Subnet ********************/

resource "aws_subnet" "main" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.subnet_cidr_block}"
  availability_zone_id    = "${data.aws_availability_zone.main.zone_id}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_id}-subnet"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

/******************* Route Table ********************/

resource "aws_default_route_table" "main" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags = {
    Name = "${var.project_id}-default-route-table"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = "${aws_subnet.main.id}"
  route_table_id = "${aws_default_route_table.main.id}"
}

/******************* Associate EIPs ********************/

resource "aws_eip_association" "eip_assoc_controller" {
  instance_id   = "${aws_instance.controller.id}"
  allocation_id = "${aws_eip.controller.id}"
}

resource "aws_eip_association" "eip_assoc_gateway" {
  instance_id   = "${aws_instance.gateway.id}"
  allocation_id = "${aws_eip.gateway.id}"
}

/******************* Internet Gateway ********************/

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "${var.project_id}-internet-gateway"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

/******************* Keypair ********************/

resource "aws_key_pair" "main" {
  key_name   = "${var.project_id}-keypair"
  public_key = "${data.local_file.ssh_pub_key.content}"
}

/******************* Instance: AD Server ********************/

resource "aws_instance" "ad_server" {
  ami                    = "${var.ec2_ami}"
  instance_type          = "${var.ad_instance_type}"
  key_name               = "${aws_key_pair.main.key_name}"
  vpc_security_group_ids = [ "${aws_default_security_group.main.id}" ]
  subnet_id              = "${aws_subnet.main.id}"

  count = "${var.ad_server_enabled == true ? 1 : 0}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-ad-server"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = "${aws_instance.ad_server[0].public_ip}"
      private_key = file("${var.ssh_prv_key_path}")
    }
    destination   = "/home/centos/ad_user_setup.sh"
    content       = <<-EOT
     #!/bin/bash

     # allow weak passwords - easier to demo
     samba-tool domain passwordsettings set --complexity=off
     
     # set password expiration to highest possible value, default is 43
     samba-tool domain passwordsettings set --max-pwd-age=999
    
     # Create DemoTenantUsers group and a user ad_user1
     samba-tool group add DemoTenantUsers
     samba-tool user create ad_user1 pass123
     samba-tool group addmembers DemoTenantUsers ad_user1

     # Create DemoTenantAdmins group and a user ad_admin1
     samba-tool group add DemoTenantAdmins
     samba-tool user create ad_admin1 pass123
     samba-tool group addmembers DemoTenantAdmins ad_admin1
    EOT
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = "${aws_instance.ad_server[0].public_ip}"
      private_key = file("${var.ssh_prv_key_path}")
    }
    inline = [
      "sudo yum install -y docker openldap-clients",
      "sudo service docker start",
      "sudo systemctl enable docker",
      <<EOT
      sudo docker run --privileged --restart=unless-stopped \
       -p 53:53 -p 53:53/udp -p 88:88 -p 88:88/udp -p 135:135 -p 137-138:137-138/udp -p 139:139 -p 389:389 \
       -p 389:389/udp -p 445:445 -p 464:464 -p 464:464/udp -p 636:636 -p 1024-1044:1024-1044 -p 3268-3269:3268-3269 \
       -e "SAMBA_DOMAIN=samdom" \
       -e "SAMBA_REALM=samdom.example.com" \
       -e "SAMBA_ADMIN_PASSWORD=5ambaPwd@" \
       -e "ROOT_PASSWORD=R00tPwd@" \
       -e "LDAP_ALLOW_INSECURE=true" \
       -e "SAMBA_HOST_IP=$(hostname --all-ip-addresses |cut -f 1 -d' ')" \
       -v /home/centos/ad_user_setup.sh:/usr/local/bin/custom.sh \
       --name samdom \
       --dns 127.0.0.1 \
       -d \
       --entrypoint "/bin/bash" \
       rsippl/samba-ad-dc \
       -c "chmod +x /usr/local/bin/custom.sh &&. /init.sh app:start"
      EOT
      ,
      "echo Done!"

      // To connect ...
      // LDAPTLS_REQCERT=never ldapsearch -o ldif-wrap=no -x -H ldaps://localhost:636 -D 'cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com' -w '5ambaPwd@' -b 'DC=samdom,DC=example,DC=com'
    ]
  }
}

output "ad_server_private_ip" {
  value = "${aws_instance.ad_server[0].private_ip}"
}

output "ad_server_ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.ad_server[0].public_ip}"
}


/******************* Instance: NFS Server (e.g. for ML OPS) ********************/

resource "aws_instance" "nfs_server" {
  ami                    = "${var.ec2_ami}"
  instance_type          = "${var.nfs_instance_type}"
  key_name               = "${aws_key_pair.main.key_name}"
  vpc_security_group_ids = [ "${aws_default_security_group.main.id}" ]
  subnet_id              = "${aws_subnet.main.id}"

  count = "${var.nfs_server_enabled == true ? 1 : 0}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-nfs-server"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = "${aws_instance.nfs_server[0].public_ip}"
      private_key = file("${var.ssh_prv_key_path}")
    }
    inline = [
      "sudo yum -y install nfs-utils",
      "sudo mkdir /nfsroot",
      "echo '/nfsroot *(rw,no_root_squash,no_subtree_check)' | sudo tee /etc/exports",
      "sudo exportfs -r",
      "sudo systemctl enable nfs-server.service",
      "sudo systemctl start nfs-server.service"
    ]
  }
}

output "nfs_server_private_ip" {
  value = "${aws_instance.nfs_server[0].private_ip}"
}

output "nfs_server_folder" {
  value = "/nfsroot"
}

output "nfs_server_ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.nfs_server[0].public_ip}"
}

/******************* Instance: Gateway ********************/

resource "aws_instance" "gateway" {
  ami                    = "${var.ec2_ami}"
  instance_type          = "${var.gtw_instance_type}"
  key_name               = "${aws_key_pair.main.key_name}"
  vpc_security_group_ids = [ "${aws_default_security_group.main.id}" ]
  subnet_id              = "${aws_subnet.main.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-gateway"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
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


//////////////////// Instance: Controller /////////////////////

resource "aws_instance" "controller" {
  ami                    = "${var.ec2_ami}"
  instance_type          = "${var.ctr_instance_type}"
  key_name               = "${aws_key_pair.main.key_name}"
  vpc_security_group_ids = [ "${aws_default_security_group.main.id}" ]
  subnet_id              = "${aws_subnet.main.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-controller"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

# /dev/sdb

resource "aws_ebs_volume" "controller-ebs-sdb" {
  availability_zone = "${var.az}"
  size              = 512
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-controller-ebs-sdb"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_volume_attachment" "controller-volume-attachment-sdb" {
  device_name = "/dev/sdb"
  volume_id   = "${aws_ebs_volume.controller-ebs-sdb.id}"
  instance_id = "${aws_instance.controller.id}"

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdc

resource "aws_ebs_volume" "controller-ebs-sdc" {
  availability_zone = "${var.az}"
  size              = 512
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-controller-ebs-sdc"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_volume_attachment" "controller-volume-attachment-sdc" {
  device_name = "/dev/sdc"
  volume_id   = "${aws_ebs_volume.controller-ebs-sdc.id}"
  instance_id = "${aws_instance.controller.id}"

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# print IP address

output "controller_public_ip" {
  value = "${aws_eip.controller.public_ip}"
}

output "controller_private_ip" {
  value = "${aws_instance.controller.private_ip}"
}

//////////////////// Instance: Workers /////////////////////

resource "aws_instance" "workers" {
  count                  = "${var.worker_count}"
  ami                    = "${var.ec2_ami}"
  instance_type          = "${var.wkr_instance_type}"
  key_name               = "${aws_key_pair.main.key_name}"
  vpc_security_group_ids = [ "${aws_default_security_group.main.id}" ]
  subnet_id              = "${aws_subnet.main.id}"

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-worker-${count.index + 1}"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

# /dev/sdb

resource "aws_ebs_volume" "worker-ebs-volumes-sdb" {
  count             = "${var.worker_count}"
  availability_zone = "${var.az}"
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-worker-${count.index + 1}-ebs-sdb"
    Project = "${var.project_id}"
  }
}

resource "aws_volume_attachment" "worker-volume-attachment-sdb" {
  count       = "${var.worker_count}"
  device_name = "/dev/sdb"
  volume_id   = "${aws_ebs_volume.worker-ebs-volumes-sdb.*.id[count.index]}"
  instance_id = "${aws_instance.workers.*.id[count.index]}"

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdc

resource "aws_ebs_volume" "worker-ebs-volumes-sdc" {
  count             = "${var.worker_count}"
  availability_zone = "${var.az}"
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-worker-${count.index + 1}-ebs-sdc"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_volume_attachment" "worker-volume-attachment-sdc" {
  count       = "${var.worker_count}"
  device_name = "/dev/sdc"
  volume_id   = "${aws_ebs_volume.worker-ebs-volumes-sdc.*.id[count.index]}"
  instance_id = "${aws_instance.workers.*.id[count.index]}"

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
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

/* Disabling this functinoality due to a bug in terraform: https://github.com/hashicorp/terraform/issues/4131

//////////////////// Cloudwatch /////////////////////

// Adapted from: https://gist.github.com/picadoh/815c11361d1a88419ea16b14fe044e85

# create a lambda script for stopping the EC2 instances created by this terraform script

resource "local_file" "stop_instances_lambda" {
  filename = "${path.module}/generated/stop_instances_lambda.py"
  content = <<-EOF
  import boto3

  # Boto Connection
  ec2 = boto3.resource('ec2', '${var.region}')

  def lambda_handler(event, context):
    instance_ids = ["${aws_instance.controller.id}","${aws_instance.gateway.id}","${join("\",\"", aws_instance.workers.*.id)}"]
    stopping_instances = ec2.instances.filter(InstanceIds=instance_ids).stop()
  EOF
}

# lambda requires the script to be uploaded in a zip file

data "archive_file" "stop_scheduler" {
  type        = "zip"
  depends_on  = ["local_file.stop_instances_lambda"]
  source_file = "${path.module}/generated/stop_instances_lambda.py"
  output_path = "${path.module}/generated/stop_instances_lambda.zip"
}

resource "aws_lambda_function" "ec2_stop_scheduler_lambda" {
  filename = "${data.archive_file.stop_scheduler.output_path}"
  function_name = "stop_instances_lambda"
  role = "${aws_iam_role.ec2_stop_scheduler.arn}"
  handler = "stop_instances_lambda.lambda_handler"
  runtime = "python2.7"
  timeout = 300
  source_code_hash = "${data.archive_file.stop_scheduler.output_base64sha256}"

  tags = {
    Name = "${var.project_id}-aws-lambda-function"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

### IAM Role and Policy - allows Lambda function to describe and stop EC2 instances

resource "aws_iam_role" "ec2_stop_scheduler" {
  name = "${var.project_id}-ec2_stop_scheduler"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "${var.project_id}-aws-iam-role"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

data "aws_iam_policy_document" "ec2_stop_scheduler" {
  statement {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = [ "arn:aws:logs:*:*:*" ]
  }
  statement {
      effect = "Allow"
      actions = ["ec2:Describe*","ec2:Stop*"]
      resources = [ "*" ]
  }
}

resource "aws_iam_policy" "ec2_stop_scheduler" {
  name = "${var.project_id}-ec2_access_scheduler"
  path = "/"
  policy = "${data.aws_iam_policy_document.ec2_stop_scheduler.json}"
}

resource "aws_iam_role_policy_attachment" "ec2_access_scheduler" {
  role       = "${aws_iam_role.ec2_stop_scheduler.name}"
  policy_arn = "${aws_iam_policy.ec2_stop_scheduler.arn}"
}

### Cloudwatch Events ###

resource "aws_cloudwatch_event_rule" "stop_instances_event_rule" {
  name = "${var.project_id}-stop_instances_event_rule"
  description = "Stops running EC2 instances"

  # note schedules are UTC time zone - https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
  schedule_expression = "${var.ec2_shutdown_schedule_expression}"
  is_enabled = "${var.ec2_shutdown_schedule_is_enabled}"
  depends_on = ["aws_lambda_function.ec2_stop_scheduler_lambda"]

  tags = {
    Name = "${var.project_id}-aws-cloudwatch-event-rule"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_cloudwatch_event_target" "stop_instances_event_target" {
  target_id = "stop_instances_lambda_target"
  rule = "${aws_cloudwatch_event_rule.stop_instances_event_rule.name}"
  arn = "${aws_lambda_function.ec2_stop_scheduler_lambda.arn}"
}

# AWS Lambda Permissions: Allow CloudWatch to execute the Lambda Functions

resource "aws_lambda_permission" "allow_cloudwatch_to_call_stop_scheduler" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ec2_stop_scheduler_lambda.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.stop_instances_event_rule.arn}"
}

output "ec2_shutdown_schedule_expression" {
  value = "${var.ec2_shutdown_schedule_expression}"
}

output "ec2_shutdown_schedule_is_enabled" {
  value = "${var.ec2_shutdown_schedule_is_enabled}"
}

*/

//////////////////// Utility scripts  /////////////////////

/// instance start/stop/status

resource "local_file" "cli_stop_ec2_instances" {
  filename = "${path.module}/generated/cli_stop_ec2_instances.sh"
  content =  <<-EOF
    aws --region ${var.region} --profile ${var.profile} ec2 stop-instances --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", aws_instance.nfs_server.*.id)} ${join(" ", aws_instance.ad_server.*.id)} ${join(" ", aws_instance.workers.*.id)} 
  EOF
}

resource "local_file" "cli_start_ec2_instances" {
  filename = "${path.module}/generated/cli_start_ec2_instances.sh"
  content = <<-EOF
    aws --region ${var.region} --profile ${var.profile} ec2 start-instances --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", aws_instance.nfs_server.*.id)} ${join(" ", aws_instance.ad_server.*.id)} ${join(" ", aws_instance.workers.*.id)}
  EOF
}

resource "local_file" "cli_running_ec2_instances" {
  filename = "${path.module}/generated/cli_running_ec2_instances.sh"
  content = <<-EOF
    echo Running: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", aws_instance.nfs_server.*.id)} ${join(" ", aws_instance.ad_server.*.id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=running --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Starting: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", aws_instance.nfs_server.*.id)} ${join(" ", aws_instance.ad_server.*.id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=pending --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Stopping: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", aws_instance.nfs_server.*.id)} ${join(" ", aws_instance.ad_server.*.id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=stopping --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Stopped: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", aws_instance.nfs_server.*.id)} ${join(" ", aws_instance.ad_server.*.id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=stopped --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
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
