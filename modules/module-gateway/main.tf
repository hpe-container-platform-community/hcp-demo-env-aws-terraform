
resource "aws_eip" "gateway" {
  vpc = true
  count = var.create_eip ? 1 : 0
  tags = {
    Name = "${var.project_id}-gateway"
    Project = var.project_id
    user = var.user
    deployment_uuid = var.deployment_uuid
  }
}

// EIP associations

resource "aws_eip_association" "eip_assoc_gateway" {
  count = var.create_eip ? 1 : 0
  instance_id   = aws_instance.gateway.id
  allocation_id = aws_eip.gateway[0].id
}

// Instance

resource "aws_instance" "gateway" {
  ami                    = var.ec2_ami
  instance_type          = var.gtw_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-gateway"
    Project = var.project_id
    user = var.user
    deployment_uuid = var.deployment_uuid
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = aws_instance.gateway.public_ip
      private_key = file(var.ssh_prv_key_path)
      agent       = false
    }
    inline = [
      "sudo yum update -y -q"
    ]
  }
}
