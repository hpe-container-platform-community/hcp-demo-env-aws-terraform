
resource "aws_eip" "gateway" {
  vpc = true

  tags = {
    Name = "${var.project_id}-gateway"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

// EIP associations

resource "aws_eip_association" "eip_assoc_gateway" {
  instance_id   = aws_instance.gateway.id
  allocation_id = aws_eip.gateway.id
}


// Instance

resource "aws_instance" "gateway" {
  ami                    = var.EC2_CENTOS7_AMIS[var.region]
  instance_type          = var.gtw_instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [ module.network.security_group_main_id ]
  subnet_id              = module.network.subnet_main_id

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
