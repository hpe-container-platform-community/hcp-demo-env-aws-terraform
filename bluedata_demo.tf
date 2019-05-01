// Usage: terraform <action> -var-file="bluedata_demo.tfvars"

variable "region" { }
variable "az" { }
variable "project_id" { }
variable "user" { }
variable "client_cidr_block" {  }
variable "check_client_ip" { default = "true" }
variable "vpc_cidr_block" { }
variable "subnet_cidr_block" { }
variable "ssh_pub_key" { }
variable "ec2_ami" { }
variable "ssh_prv_key_path" {}
variable "worker_count" { default = 3 }

variable "gtw_instance_type" { default = "m4.2xlarge" }
variable "ctr_instance_type" { default = "m4.2xlarge" }
variable "wkr_instance_type" { default = "m4.2xlarge" }

variable "epic_dl_url" { }
variable "epic_precheck_dl_url" { } 
variable "epic_rpm_dl_url" { } 

variable "continue_on_precheck_fail" { default = "false" }

/******************* verify client ip ********************/

data "external" "example1" {
 program = [ "python3", "${path.module}/verify_client_ip.py", "${var.client_cidr_block}", "${var.check_client_ip}" ]
}

output "client_cidr_block" {
 value = "${var.client_cidr_block}"
}

/******************* setup region and az ********************/

provider "aws" {
  region = "${var.region}"
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
  public_key = "${var.ssh_pub_key}"
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

output "gateway_ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.gateway.public_ip}"
}

output "gateway_private_ip" {
  value = "${aws_instance.gateway.private_ip}"
}
output "gateway_private_dns" {
  value = "${aws_instance.gateway.private_dns}"
}
output "gateway_public_ip" {
  value = "${aws_instance.gateway.public_ip}"
}
output "gateway_public_dns" {
  value = "${aws_instance.gateway.public_dns}"
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
}

# print controller ssh command

output "controller_ssh_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.controller.public_ip}"
}

# print public IP address

output "controller public ip" {
  value = "${aws_instance.controller.public_ip}"
}

//////////////////// Instance: Workers /////////////////////

resource "aws_instance" "workers" {
  count                  = 3
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
  count             = "${aws_instance.workers.count}"
  availability_zone = "${var.az}"
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-worker-${count.index + 1}-ebs-sdb"
    Project = "${var.project_id}"
  }
}

resource "aws_volume_attachment" "worker-volume-attachment-sdb" {
  count       = "${aws_instance.workers.count}"
  device_name = "/dev/sdb"
  volume_id   = "${aws_ebs_volume.worker-ebs-volumes-sdb.*.id[count.index]}"
  instance_id = "${aws_instance.workers.*.id[count.index]}"
}

# /dev/sdc

resource "aws_ebs_volume" "worker-ebs-volumes-sdc" {
  count             = "${aws_instance.workers.count}"
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
  count       = "${aws_instance.workers.count}"
  device_name = "/dev/sdc"
  volume_id   = "${aws_ebs_volume.worker-ebs-volumes-sdc.*.id[count.index]}"
  instance_id = "${aws_instance.workers.*.id[count.index]}"
}

# TODO - terraform 0.12 has a 'for' operator to fix this hardcoding
output "workers_ssh" {
  value = [ "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.workers.0.public_ip}",
            "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.workers.1.public_ip}",
            "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.workers.2.public_ip}" ]
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

////////////////////////////////// Copy controller instance ssh pub key to other instances ////////////////////////////////// 

# TODO this will only work on local machines with ssh client installed (probably *nix only)

resource "null_resource" "create_controller_public_key" {

  depends_on = [ "aws_instance.controller" ]

  provisioner "local-exec" {
    command = <<EOF
	# FIXME nasty hack, waiting before creating key
        sleep 60

	ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.controller.public_ip} "if [ ! -f ~/.ssh/id_rsa ]; then ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa; fi" 

  ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.controller.public_ip} "cat ~/.ssh/id_rsa.pub >> /home/centos/.ssh/authorized_keys" 

  # test connection from controller to gateway
  ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.controller.public_ip} "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa centos@${aws_instance.controller.private_ip} "echo connected""
EOF
  }
}

resource "null_resource" "copy_controller_public_key_to_gateway" {

  depends_on = [ "null_resource.create_controller_public_key" ]

  provisioner "local-exec" {
    command = <<EOF
	ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.controller.public_ip} "cat /home/centos/.ssh/id_rsa.pub" | \
	  ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.gateway.public_ip} "cat >> /home/centos/.ssh/authorized_keys" 

  # test connection from controller to gateway
  ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.controller.public_ip} "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa centos@${aws_instance.gateway.private_ip} "echo connected""
EOF
  }
}

resource "null_resource" "copy_controller_public_key_to_workers" {

  count = "${var.worker_count}"
  depends_on = [ "null_resource.create_controller_public_key" ]

  provisioner "local-exec" {
    command = <<EOF
	ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.controller.public_ip} "cat /home/centos/.ssh/id_rsa.pub" | \
	  ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${element(aws_instance.workers.*.public_ip, count.index)} "cat >> /home/centos/.ssh/authorized_keys" 

  # test connection from controller to worker
  ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.controller.public_ip} "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa centos@${element(aws_instance.workers.*.private_ip, count.index)} "echo connected""
EOF
  }
}

////////////////////////////////// gateway setup ////////////////////////////////// 

resource "null_resource" "gateway_setup" {

  depends_on = [ 
    "null_resource.copy_controller_public_key_to_gateway",
    "null_resource.copy_controller_public_key_to_workers"
  ]

  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = "centos"
      host  = "${aws_instance.gateway.public_ip}"
    }
    inline = [
      # install RPMs
      "curl -s ${var.epic_rpm_dl_url} | grep proxy | awk '{print $3}' | sed -r \"s/([a-zA-Z0-9_+]*)(-[a-zA-Z0-9]+)?(-\\S+)(-.*)/\\1\\2\\3/\" | xargs sudo yum install -y 2>&1 > ~/install_rpm.log",
    ]
  }
  provisioner "local-exec" {
    # FIXME see https://github.com/hashicorp/terraform/issues/17844#issuecomment-446674465
    # command = "aws ec2 reboot-instances --instance-ids ${aws_instance.gateway.id}"
    command = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.gateway.public_ip} '(sleep 2; sudo reboot)&'"
  }
}


////////////////////////////////// controller precheck ////////////////////////////////// 

resource "null_resource" "controller_precheck" {

  depends_on = [ 
	      "aws_instance.controller",
      	"aws_instance.gateway",
        "null_resource.gateway_setup"
	]

  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = "centos"
      host  = "${aws_instance.controller.public_ip}"
    }
    inline = [
      # install RPMs
      "curl -s ${var.epic_rpm_dl_url} | grep ctrl | awk '{print $3}' | sed -r \"s/([a-zA-Z0-9_+]*)(-[a-zA-Z0-9]+)?(-\\S+)(-.*)/\\1\\2\\3/\" | xargs sudo yum install -y 2>&1 > ~/install_rpm.log",
    ]
  }
  provisioner "local-exec" {
    # FIXME see https://github.com/hashicorp/terraform/issues/17844#issuecomment-446674465
    # command = "aws ec2 reboot-instances --instance-ids ${aws_instance.controller.id}"
    command = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.controller.public_ip} '(sleep 2; sudo reboot)&'"
  }
  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = "centos"
      host  = "${aws_instance.controller.public_ip}"
    }
    inline = [
      # install precheck scripts
      "curl -s -o bluedata-prechecks-epic-entdoc-3.7.bin ${var.epic_precheck_dl_url}",
      "chmod +x bluedata-prechecks-epic-entdoc-3.7.bin",

      # run precheck
      "sudo ./bluedata-prechecks-epic-entdoc-3.7.bin -c --controller-ip ${aws_instance.controller.private_ip} --gateway-node-ip ${aws_instance.gateway.private_ip} --gateway-node-hostname ${aws_instance.gateway.private_dns} 2>&1 > /home/centos/bluedata-precheck.log"
    ]
  }
}

////////////////////////////////// worker precheck ////////////////////////////////// 

resource "null_resource" "worker_precheck" {

  count = "${var.worker_count}"

  depends_on = [
    "null_resource.gateway_setup",
    "null_resource.copy_controller_public_key_to_gateway",
    "null_resource.copy_controller_public_key_to_workers",
    "aws_volume_attachment.worker-volume-attachment-sdb",
    "aws_volume_attachment.worker-volume-attachment-sdc"
  ]

  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = "centos"
      host  = "${element(aws_instance.workers.*.public_ip, count.index)}" 
    }
    inline = [
      # install RPMs
      "curl -s ${var.epic_rpm_dl_url} | grep \"wrkr \" | awk '{print $3}' | sed -r \"s/([a-zA-Z0-9_+]*)(-[a-zA-Z0-9]+)?(-\\S+)(-.*)/\\1\\2\\3/\" | xargs sudo yum install -y 2>&1 > ~/install.rpm.log",
    ]
  }
  provisioner "local-exec" {
    # FIXME see https://github.com/hashicorp/terraform/issues/17844#issuecomment-446674465
    # command = "aws ec2 reboot-instances --instance-ids ${element(aws_instance.workers.*.id, count.index)}"
    command = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${element(aws_instance.workers.*.public_ip, count.index)} '(sleep 2; sudo reboot)&'"
  }
  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = "centos"
      host  = "${element(aws_instance.workers.*.public_ip, count.index)}" 
    }
    inline = [
      # install precheck scripts
      "curl -s -o bluedata-prechecks-epic-entdoc-3.7.bin ${var.epic_precheck_dl_url}",
      "chmod +x bluedata-prechecks-epic-entdoc-3.7.bin",

      # run precheck
      "while ! mountpoint -x /dev/xvdb; do sleep 1; done",
      "while ! mountpoint -x /dev/xvdc; do sleep 1; done",
      "if [ ${var.continue_on_precheck_fail} == 'true' ]; then sudo ./bluedata-prechecks-epic-entdoc-3.7.bin -w --worker-primary-ip ${element(aws_instance.workers.*.private_ip, count.index)} --controller-ip ${aws_instance.controller.private_ip} --gateway-node-ip ${aws_instance.gateway.public_ip} --gateway-node-hostname ${aws_instance.gateway.public_dns} || true 2>&1 > /home/centos/bluedata-precheck.log; fi",
      "if [ ${var.continue_on_precheck_fail} != 'true' ]; then sudo ./bluedata-prechecks-epic-entdoc-3.7.bin -w --worker-primary-ip ${element(aws_instance.workers.*.private_ip, count.index)} --controller-ip ${aws_instance.controller.private_ip} --gateway-node-ip ${aws_instance.gateway.public_ip} --gateway-node-hostname ${aws_instance.gateway.public_dns} 2>&1 > /home/centos/bluedata-precheck.log; fi"
    ]
  }
}

////////////////////////////////// install controller ////////////////////////////////// 

resource "null_resource" "install_controller" {

  depends_on = [ 
	"null_resource.controller_precheck",
	"null_resource.worker_precheck"
	]

  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = "centos"
      host  = "${aws_instance.controller.public_ip}"
    }
    inline = [
      # download EPIC
      "curl -s -o bluedata-epic-entdoc-minimal-release-3.7-2207.bin ${var.epic_dl_url}",
      "chmod +x bluedata-epic-entdoc-minimal-release-3.7-2207.bin",

      # install EPIC 
      "sudo ./bluedata-epic-entdoc-minimal-release-3.7-2207.bin -s -i -c ${aws_instance.controller.private_ip} --user centos --group centos",
      
      # install  application workbench
      "sudo yum install -y python-pip",
      "sudo pip install --upgrade pip",
      "sudo pip install --upgrade setuptools",
      "sudo pip install --upgrade bdworkbench"
    ]
  }
}

# FIXME We have to manually configure gateway and workers using controller UI for now until the code below is fixed

// ////////////////////////////////// gateway agent ////////////////////////////////// 
// 
// resource "null_resource" "gateway_agent" {
// 
//   depends_on = [ "null_resource.install_controller" ]
// 
//   provisioner "remote-exec" {
//     connection {
//       type  = "ssh"
//       user  = "centos"
//       host  = "${aws_instance.gateway.public_ip}"
//     }
//     inline = [
//       # agent-install-worker.parms
//       "curl -s -o /tmp/agent-install-worker.parms https://s3.amazonaws.com/bluedata-releases/3.7/agent-install-worker.parms",
//       "sed -i s/^#HAENABLED=false.*$/HAENABLED=false/g /tmp/agent-install-worker.parms",
//       "sed -i s/^#CONTROLLER=.*$/CONTROLLER=${aws_instance.controller.private_ip}/g /tmp/agent-install-worker.parms",
//       "sed -i s/^#CONTROLLER_HOSTNAME=.*$/CONTROLLER_HOSTNAME=${aws_instance.controller.private_dns}/g /tmp/agent-install-worker.parms",
//       "sed -i s/^#BLUEDATA_USER=.*$/BLUEDATA_USER=centos/g /tmp/agent-install-worker.parms",
//       "sed -i s/^#BLUEDATA_GROUP=.*$/BLUEDATA_GROUP=centos/g /tmp/agent-install-worker.parms",
// 
//       # download EPIC
//       "curl -s -o bluedata-epic-entdoc-minimal-release-3.7-2207.bin ${var.epic_dl_url}",
//       "chmod +x bluedata-epic-entdoc-minimal-release-3.7-2207.bin",
// 
//       # install agent
//       "sudo ./bluedata-epic-entdoc-minimal-release-3.7-2207.bin --params /tmp/agent-install-worker.parms --nodetype proxy --gateway-node-ip ${aws_instance.gateway.private_ip} --gateway-node-hostname ${aws_instance.gateway.private_dns}"
//     ]
//   }
// }
// 
// ////////////////////////////////// worker agent ////////////////////////////////// 
// 
// resource "null_resource" "worker_agent" {
// 
//   count = "${var.worker_count}"
//   depends_on = [ "null_resource.install_controller" ]
// 
//   provisioner "remote-exec" {
//     connection {
//       type  = "ssh"
//       user  = "centos"
//       host  = "${element(aws_instance.workers.*.public_ip, count.index)}"
//     }
//     inline = [
//       # agent-install-worker.parms
//       "curl -s -o /tmp/agent-install-worker.parms https://s3.amazonaws.com/bluedata-releases/3.7/agent-install-worker.parms",
//       "sed -i s/^#HAENABLED=false.*$/HAENABLED=false/g /tmp/agent-install-worker.parms",
//       "sed -i s/^#CONTROLLER=.*$/CONTROLLER=${aws_instance.controller.private_ip}/g /tmp/agent-install-worker.parms",
//       "sed -i s/^#CONTROLLER_HOSTNAME=.*$/CONTROLLER_HOSTNAME=${aws_instance.controller.private_dns}/g /tmp/agent-install-worker.parms",
//       "sed -i s/^#BLUEDATA_USER=.*$/BLUEDATA_USER=centos/g /tmp/agent-install-worker.parms",
//       "sed -i s/^#BLUEDATA_GROUP=.*$/BLUEDATA_GROUP=centos/g /tmp/agent-install-worker.parms",
// 
//       # download EPIC
//       "curl -s -o bluedata-epic-entdoc-minimal-release-3.7-2207.bin ${var.epic_dl_url}",
//       "chmod +x bluedata-epic-entdoc-minimal-release-3.7-2207.bin",
// 
//       # run precheck
//       "sudo ./bluedata-epic-entdoc-minimal-release-3.7-2207.bin --params /tmp/agent-install-worker.parms --nodetype worker --worker ${element(aws_instance.workers.*.private_ip, count.index)} --workerhostname ${element(aws_instance.workers.*.private_dns, count.index)}"
//     ]
//   }
// }

////////////////////////////////// Display configuration URL ////////////////////////////////// 

output "display_configuration_url" {
  value = "Controller Configuration URL: http://${aws_instance.controller.public_ip}"
}
output "retrive_controller_ssh" {
  value = "ssh -o StrictHostKeyChecking=no -i ${var.ssh_prv_key_path} centos@${aws_instance.controller.public_ip} 'cat ~/.ssh/id_rsa' > controller.prv_key"
}
