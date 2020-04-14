data "template_file" "hcp_desktop_link" {
  template = file("${path.module}/Templates/HCP.admin.desktop.tpl")
  vars = {
    controller_private_ip = var.controller_private_ip
  }
}

data "template_file" "mcs_desktop_link" {
  template = file("${path.module}/Templates/MCS.admin.desktop.tpl")
  vars = {
    controller_private_ip = var.controller_private_ip
  }
}

data "template_file" "hcp_links_desktop_link" {
  template = file("${path.module}/Templates/startup.desktop.tpl")
  vars = {
    controller_private_ip = var.controller_private_ip
  }
}

resource "aws_instance" "rdp_server" {
  ami                    = var.rdp_ec2_ami
  instance_type          = var.rdp_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id
 
  count = var.rdp_server_enabled == true ? 1 : 0

  root_block_device {
    volume_type = "gp2"
    volume_size = 41
  }

  // ready for hibernation support
  // note that not yet supported by terraform: https://github.com/terraform-providers/terraform-provider-aws/issues/6638
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp2"
    volume_size = 40
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.rdp_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    inline = [
      //"sudo bash -c \"echo 'deb https://package.mapr.com/releases/v6.1.0/ubuntu binary trusty' > /etc/apt/sources.list.d/mapr.list\"",
      //"sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BFDDB60966B3F0D6",
      //"wget -O - https://package.mapr.com/releases/pub/maprgpg.key | sudo apt-key add -",
      "sudo sed -i 's/1/0/g' /etc/apt/apt.conf.d/20auto-upgrades",
      "sudo apt update",
      "sudo apt install -y firefox",
      "sudo snap install gedit",
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/kubectl",
      "echo 'source <(kubectl completion bash)' >>~/.bashrc",
      "sudo bash -c 'kubectl completion bash >/etc/bash_completion.d/kubectl'",
      "echo 'alias k=kubectl' >>~/.bashrc",
      "echo 'complete -F __start_kubectl k' >>~/.bashrc",
      "curl -L0 https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip > terraform_0.12.24_linux_amd64.zip",
      "unzip terraform_0.12.24_linux_amd64.zip",
      "chmod a+x terraform",
      "sudo mv terraform /usr/local/bin/",
      "rm terraform_0.12.24_linux_amd64.zip",
      "mkdir /home/ubuntu/Desktop",
      //"chmod 600 /home/ubuntu/.ssh/id_rsa",
      "sudo bash -c \"fastdd & disown -h %1\"" # prewarm EBS for faster operation
    ]
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.rdp_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    source        = "${path.module}/Desktop/"
    destination   = "/home/ubuntu/Desktop"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.rdp_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    content        = data.template_file.mcs_desktop_link.rendered
    destination   = "/home/ubuntu/Desktop/MCS.admin.desktop"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.rdp_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    content        = data.template_file.hcp_desktop_link.rendered
    destination   = "/home/ubuntu/Desktop/HCP.admin.desktop"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.rdp_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    content        = data.template_file.hcp_links_desktop_link.rendered
    destination   = "/home/ubuntu/Desktop/startup.desktop"
  }

  // 'enable' desktop icons 
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.rdp_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    inline = [
      //"sudo chown ubuntu:ubuntu /home/ubuntu/.local/share/gvfs-metadata/home*",
      "sudo chmod +x /home/ubuntu/Desktop/*.desktop",
      // set firefox to autostart  
      "sudo cp Desktop/startup.desktop /etc/xdg/autostart/",
    ]
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.rdp_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    destination   = "/home/ubuntu/hcp-ca-cert.pem"
    content       = var.ca_cert
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.rdp_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    source        = "${path.module}/ca-certs-setup.sh"
    destination   = "/tmp/ca-certs-setup.sh"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = aws_instance.rdp_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
    }
    inline = [
      "chmod +x /tmp/ca-certs-setup.sh",
      "/tmp/ca-certs-setup.sh ${var.controller_private_ip}",
    ]
  }

  tags = {
    Name = "${var.project_id}-instance-rdp-server-linux"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}