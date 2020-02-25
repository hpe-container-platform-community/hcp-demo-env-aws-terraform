// Usage: terraform <action> -var-file="bluedata_infra.tfvars"

terraform {
  required_version = ">= 0.12.0"
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
 program = [ "python3", "${path.module}/scripts/verify_client_ip.py", "${var.client_cidr_block}", "${var.check_client_ip}" ]
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

/******************* modules ********************/

module "nfs_server" {
  source = "./modules/module-nfs-server"
  project_id = var.project_id
  user = var.user
  ssh_prv_key_path = var.ssh_prv_key_path
  nfs_ec2_ami = var.ec2_ami
  nfs_instance_type = var.nfs_instance_type
  nfs_server_enabled = var.nfs_server_enabled
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = [ "${aws_default_security_group.main.id}" ]
  subnet_id = aws_subnet.main.id
}

module "ad_server" {
  source = "./modules/module-ad-server"
  project_id = var.project_id
  user = var.user
  ssh_prv_key_path = var.ssh_prv_key_path
  ad_ec2_ami = var.ec2_ami
  ad_instance_type = var.ad_instance_type
  ad_server_enabled = var.ad_server_enabled
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = [ "${aws_default_security_group.main.id}" ]
  subnet_id = aws_subnet.main.id
}

module "rdp_server" {
  source = "./modules/module-rdp-server"
  project_id = var.project_id
  user = var.user
  ssh_prv_key_path = var.ssh_prv_key_path
  rdp_ec2_ami = var.ec2_ami
  rdp_instance_type = var.rdp_instance_type
  rdp_server_enabled = var.rdp_server_enabled
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = [ "${aws_default_security_group.main.id}" ]
  subnet_id = aws_subnet.main.id
}


//////////////////// Utility scripts  /////////////////////

/// instance start/stop/status

resource "local_file" "cli_stop_ec2_instances" {
  filename = "${path.module}/generated/cli_stop_ec2_instances.sh"
  content =  <<-EOF
    aws --region ${var.region} --profile ${var.profile} ec2 stop-instances --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", aws_instance.workers.*.id)} 
  EOF
}

resource "local_file" "cli_start_ec2_instances" {
  filename = "${path.module}/generated/cli_start_ec2_instances.sh"
  content = <<-EOF
    aws --region ${var.region} --profile ${var.profile} ec2 start-instances --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", aws_instance.workers.*.id)}
  EOF
}

resource "local_file" "cli_running_ec2_instances" {
  filename = "${path.module}/generated/cli_running_ec2_instances.sh"
  content = <<-EOF
    echo Running: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=running --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Starting: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=pending --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Stopping: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=stopping --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Stopped: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${aws_instance.controller.id} ${aws_instance.gateway.id} ${join(" ", module.nfs_server.instance_id)} ${join(" ", module.ad_server.instance_id)} ${join(" ", aws_instance.workers.*.id)} --filter Name=instance-state-name,Values=stopped --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
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
