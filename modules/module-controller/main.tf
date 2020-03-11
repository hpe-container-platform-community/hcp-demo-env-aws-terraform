/******************* elastic ips ********************/

resource "aws_eip" "controller" {
  vpc = true
  count = var.create_eip ? 1 : 0
  tags = {
    Name = "${var.project_id}-controller"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

// EIP associations

resource "aws_eip_association" "eip_assoc_controller" {
  count = var.create_eip ? 1 : 0
  instance_id   = aws_instance.controller.id
  allocation_id = aws_eip.controller[0].id
}

// Instance

resource "aws_instance" "controller" {
  ami                    = var.ec2_ami
  instance_type          = var.ctr_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-controller"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = aws_instance.controller.public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    inline = [
      "sudo yum update -y"
    ]
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