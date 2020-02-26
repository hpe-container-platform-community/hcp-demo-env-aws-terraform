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
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = aws_instance.ad_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    destination   = "/home/centos/ad_user_setup.sh"
    content       = <<-EOT
     #!/bin/bash

     # allow weak passwords - easier to demo
     samba-tool domain passwordsettings set --complexity=off
     
     # set password expiration to highest possible value, default is 43
     samba-tool domain passwordsettings set --max-pwd-age=999
    
     # Create DemoTenantUsers group and a user ad_user1
     samba-tool group add DemoTenantUsers
     samba-tool user create ad_user1 pass123
     samba-tool group addmembers DemoTenantUsers ad_user1

     # Create DemoTenantAdmins group and a user ad_admin1
     samba-tool group add DemoTenantAdmins
     samba-tool user create ad_admin1 pass123
     samba-tool group addmembers DemoTenantAdmins ad_admin1
    EOT
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = aws_instance.ad_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    inline = [
      "sudo yum install -y docker openldap-clients",
      "sudo service docker start",
      "sudo systemctl enable docker",
      <<EOT
      sudo docker run --privileged --restart=unless-stopped \
       -p 53:53 -p 53:53/udp -p 88:88 -p 88:88/udp -p 135:135 -p 137-138:137-138/udp -p 139:139 -p 389:389 \
       -p 389:389/udp -p 445:445 -p 464:464 -p 464:464/udp -p 636:636 -p 1024-1044:1024-1044 -p 3268-3269:3268-3269 \
       -e "SAMBA_DOMAIN=samdom" \
       -e "SAMBA_REALM=samdom.example.com" \
       -e "SAMBA_ADMIN_PASSWORD=5ambaPwd@" \
       -e "ROOT_PASSWORD=R00tPwd@" \
       -e "LDAP_ALLOW_INSECURE=true" \
       -e "SAMBA_HOST_IP=$(hostname --all-ip-addresses |cut -f 1 -d' ')" \
       -v /home/centos/ad_user_setup.sh:/usr/local/bin/custom.sh \
       --name samdom \
       --dns 127.0.0.1 \
       -d \
       --entrypoint "/bin/bash" \
       rsippl/samba-ad-dc \
       -c "chmod +x /usr/local/bin/custom.sh &&. /init.sh app:start"
      EOT
      ,
      "echo Done!"

      // To connect ...
      // LDAPTLS_REQCERT=never ldapsearch -o ldif-wrap=no -x -H ldaps://localhost:636 -D 'cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com' -w '5ambaPwd@' -b 'DC=samdom,DC=example,DC=com'
    ]
  }
}