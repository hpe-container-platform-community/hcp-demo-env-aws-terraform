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
  }

  tags = {
    Name = "${var.project_id}-instance-ad-server"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${var.deployment_uuid}"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = aws_instance.ad_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
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
      private_key = file("${var.ssh_prv_key_path}")
      agent   = false
    }
    inline = [
      <<EOT
        set -e
        sudo yum install -y -q docker openldap-clients
        sudo service docker start
        sudo systemctl enable docker
        . /home/centos/run_ad.sh
        sleep 60
        . /home/centos/ldif_modify.sh
        echo Done!
      EOT
    ]
  }
}

// To connect ...
// LDAPTLS_REQCERT=never ldapsearch -o ldif-wrap=no -x -H ldaps://localhost:636 -D 'cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com' -w '5ambaPwd@' -b 'DC=samdom,DC=example,DC=com'
// or
// ldapsearch -o ldif-wrap=no -x -H ldap://localhost:389 -D 'cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com' -w '5ambaPwd@' -b 'DC=samdom,DC=example,DC=com'