/******************* Instance: NFS Server (e.g. for ML OPS) ********************/

resource "aws_instance" "nfs_server" {
  ami                    = var.nfs_ec2_ami
  instance_type          = var.nfs_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id

  count = var.nfs_server_enabled == true ? 1 : 0

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-nfs-server"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = aws_instance.nfs_server[0].public_ip
      private_key = file("${var.ssh_prv_key_path}")
      agent       = false
    }
    inline = [
      "sudo yum -y install nfs-utils",
      "sudo mkdir /nfsroot",
      "echo '/nfsroot *(rw,no_root_squash,no_subtree_check)' | sudo tee /etc/exports",
      "sudo exportfs -r",
      "sudo systemctl enable nfs-server.service",
      "sudo systemctl start nfs-server.service"
    ]
  }
}
