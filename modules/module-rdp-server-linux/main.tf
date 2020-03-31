
resource "aws_instance" "rdp_server" {
  ami                    = var.rdp_ec2_ami
  instance_type          = var.rdp_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id
 
  count = var.rdp_server_enabled == true ? 1 : 0

  root_block_device {
    volume_type = "gp2"
    volume_size = 40
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
      "sudo apt update && sudo apt install -y firefox",
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
      "rm terraform_0.12.24_linux_amd64.zip"
      // "nohup sudo fastdd &" # prewarm EBS for faster operation
    ]
  }

  tags = {
    Name = "${var.project_id}-instance-rdp-server-linux"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}