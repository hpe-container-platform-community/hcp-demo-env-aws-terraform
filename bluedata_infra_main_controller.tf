

/******************* elastic ips ********************/

resource "aws_eip" "controller" {
  vpc = true

  tags = {
    Name = "${var.project_id}-controller"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}
// EIP associations

resource "aws_eip_association" "eip_assoc_controller" {
  instance_id   = aws_instance.controller.id
  allocation_id = aws_eip.controller.id
}


// Instance

resource "aws_instance" "controller" {
  ami                    = var.EC2_CENTOS7_AMIS[var.region]
  instance_type          = var.ctr_instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [ module.network.security_group_main_id ]
  subnet_id              = module.network.subnet_main_id

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
  availability_zone = var.az
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
  volume_id   = aws_ebs_volume.controller-ebs-sdb.id
  instance_id = aws_instance.controller.id

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdc

resource "aws_ebs_volume" "controller-ebs-sdc" {
  availability_zone = var.az
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
  volume_id   = aws_ebs_volume.controller-ebs-sdc.id
  instance_id = aws_instance.controller.id

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}
