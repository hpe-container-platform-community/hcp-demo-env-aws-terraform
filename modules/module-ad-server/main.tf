/******************* Instance: AD Server ********************/

resource "aws_instance" "ad_server" {
  ami                    = var.ad_ec2_ami
  instance_type          = var.ad_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id

  count = var.ad_server_enabled == true ? 1 : 0

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
    tags = {
      Name = "${var.project_id}-ad-server-root-ebs"
      Project = var.project_id
      user = var.user
      deployment_uuid = var.deployment_uuid
    }
  }

  tags = {
    Name = "${var.project_id}-instance-ad-server"
    Project = var.project_id
    user = var.user
    deployment_uuid = var.deployment_uuid
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = aws_instance.ad_server[0].public_ip
      private_key = file(var.ssh_prv_key_path)
      agent   = false
    }
    source        = "${path.module}/files/"
    destination   = "/home/centos/"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = aws_instance.ad_server[0].public_ip
      private_key = file(var.ssh_prv_key_path)
      agent   = false
    }
    inline = [
      <<EOT
        set -ex
        sudo yum install -y -q docker openldap-clients
        sudo service docker start
        sudo systemctl enable docker
        sed -i s/AD_ADMIN_GROUP/${var.ad_admin_group}/g /home/centos/ad_user_setup.sh
        sed -i s/AD_MEMBER_GROUP/${var.ad_member_group}/g /home/centos/ad_user_setup.sh
        sed -i s/AD_ADMIN_GROUP/${var.ad_admin_group}/g /home/centos/ad_set_posix_classes.ldif
        sed -i s/AD_MEMBER_GROUP/${var.ad_member_group}/g /home/centos/ad_set_posix_classes.ldif
        . /home/centos/run_ad.sh
        sleep 120
        . /home/centos/ldif_modify.sh
      EOT
    ]
  }
}