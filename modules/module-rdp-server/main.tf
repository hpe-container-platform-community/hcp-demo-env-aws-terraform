/******************* Instance: RDP Server ********************/

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
    Name = "${var.project_id}-instance-rdp-server"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = "${aws_instance.rdp_server[0].public_ip}"
      private_key = file("${var.ssh_prv_key_path}")
    }
    inline = [
      "sudo yum -y update",
      "sudo yum groupinstall -y \"Server with GUI\"",
      "sudo systemctl set-default graphical.target",
      "sudo systemctl default",
      "sudo rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm",
      "sudo yum install -y xrdp tigervnc-server",
      "sudo chcon --type=bin_t /usr/sbin/xrdp",
      "sudo chcon --type=bin_t /usr/sbin/xrdp-sesman",
      "sudo systemctl start xrdp",
      "sudo systemctl enable xrdp",
      "sudo firewall-cmd --permanent --add-port=3389/tcp",
      "sudo firewall-cmd --reload",
      "sudo reboot"
    ]
  }
}
