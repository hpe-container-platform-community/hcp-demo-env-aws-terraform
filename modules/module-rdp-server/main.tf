/******************* Instance: RDP Server ********************/


data "template_file" "userdata_win" {
  template = <<EOF
<script>
echo "" > _INIT_STARTED_
net user ${var.windows_username} /add /y
net user ${var.windows_username} ${var.windows_password}
net localgroup administrators ${var.windows_username} /add
echo "" > _INIT_COMPLETE_
</script>
<persist>false</persist>
EOF
}

resource "aws_instance" "rdp_server" {
  ami                    = var.rdp_ec2_ami
  instance_type          = var.rdp_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id
  user_data              = data.template_file.userdata_win.rendered

  count = var.rdp_server_enabled == true ? 1 : 0

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-rdp-server"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}
