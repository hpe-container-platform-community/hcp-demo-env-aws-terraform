resource "aws_instance" "mapr_hosts" {
  count                  = var.mapr_count
  ami                    = var.EC2_CENTOS7_AMIS[var.region]
  instance_type          = var.wkr_instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [
    module.network.security_group_allow_all_from_client_ip,
    module.network.security_group_main_id
  ]
  subnet_id              = module.network.subnet_main_id

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-mapr-host-${count.index + 1}"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

resource "null_resource" "yum_update_mapr_hosts" {
  count = var.mapr_count

  connection {
    type        = "ssh"
    user        = "centos"
    host        = aws_instance.mapr_hosts.*.public_ip[count.index]
    private_key = file("${var.ssh_prv_key_path}")
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [ "sudo yum update -y" ]
  }
}

# /dev/sdb

resource "aws_ebs_volume" "mapr-host-ebs-volumes-sdb" {
  count             = var.mapr_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-mapr-host-${count.index + 1}-ebs-sdb"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

resource "aws_volume_attachment" "mapr-host-volume-attachment-sdb" {
  count       = var.mapr_count
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.mapr-host-ebs-volumes-sdb.*.id[count.index]
  instance_id = aws_instance.mapr_hosts.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdc

resource "aws_ebs_volume" "mapr-host-ebs-volumes-sdc" {
  count             = var.mapr_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-mapr-host-${count.index + 1}-ebs-sdc"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

resource "aws_volume_attachment" "mapr-host-volume-attachment-sdc" {
  count       = var.mapr_count
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.mapr-host-ebs-volumes-sdc.*.id[count.index]
  instance_id = aws_instance.mapr_hosts.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}
