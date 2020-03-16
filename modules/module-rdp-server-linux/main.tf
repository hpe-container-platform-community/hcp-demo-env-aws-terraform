
resource "aws_instance" "rdp_server" {
  ami                    = var.rdp_ec2_ami
  instance_type          = var.rdp_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id
 
  count = var.rdp_server_enabled == true ? 1 : 0

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-rdp-server-linux"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}
