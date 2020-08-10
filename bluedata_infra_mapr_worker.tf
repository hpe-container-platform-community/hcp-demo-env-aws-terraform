resource "aws_instance" "mapr_hosts" {
  count                  = var.mapr_count
  ami                    = var.EC2_UBUNTU1804_AMIS[var.region]
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

# /dev/sdd

resource "aws_ebs_volume" "mapr-host-ebs-volumes-sdd" {
  count             = var.mapr_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-mapr-host-${count.index + 1}-ebs-sdd"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

resource "aws_volume_attachment" "mapr-host-volume-attachment-sdd" {
  count       = var.mapr_count
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.mapr-host-ebs-volumes-sdd.*.id[count.index]
  instance_id = aws_instance.mapr_hosts.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sde

resource "aws_ebs_volume" "mapr-host-ebs-volumes-sde" {
  count             = var.mapr_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-mapr-host-${count.index + 1}-ebs-sde"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

resource "aws_volume_attachment" "mapr-host-volume-attachment-sde" {
  count       = var.mapr_count
  device_name = "/dev/sde"
  volume_id   = aws_ebs_volume.mapr-host-ebs-volumes-sde.*.id[count.index]
  instance_id = aws_instance.mapr_hosts.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdf

resource "aws_ebs_volume" "mapr-host-ebs-volumes-sdf" {
  count             = var.mapr_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-mapr-host-${count.index + 1}-ebs-sdf"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

resource "aws_volume_attachment" "mapr-host-volume-attachment-sdf" {
  count       = var.mapr_count
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mapr-host-ebs-volumes-sdf.*.id[count.index]
  instance_id = aws_instance.mapr_hosts.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}