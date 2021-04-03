resource "aws_instance" "mapr_cluster_1_hosts" {
  count                  = var.mapr_cluster_1_count
  ami                    = var.EC2_UBUNTU1804_AMIS[var.region]
  instance_type          = var.mapr_instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [
    module.network.security_group_allow_all_from_client_ip,
    module.network.security_group_main_id
  ]
  subnet_id              = module.network.subnet_main_id

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
    tags = {
      Name = "${var.project_id}-mapr-cluster-1-host-${count.index}-root-ebs"
      Project = var.project_id
      user = local.user
      deployment_uuid = random_uuid.deployment_uuid.result
    }
  }

  tags = {
    Name = "${var.project_id}-instance-mapr-cluster-1-host-${count.index}"
    Project = var.project_id
    user = local.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

# /dev/sdd

resource "aws_ebs_volume" "mapr-cluster-1-host-ebs-volumes-sdd" {
  count             = var.mapr_cluster_1_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-mapr-cluster-1-host-${count.index}-ebs-sdd"
    Project = var.project_id
    user = local.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_volume_attachment" "mapr-cluster-1-host-volume-attachment-sdd" {
  count       = var.mapr_cluster_1_count
  device_name = "/dev/sdd"
  volume_id   = aws_ebs_volume.mapr-cluster-1-host-ebs-volumes-sdd.*.id[count.index]
  instance_id = aws_instance.mapr_cluster_1_hosts.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sde

resource "aws_ebs_volume" "mapr-cluster-1-host-ebs-volumes-sde" {
  count             = var.mapr_cluster_1_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-mapr-cluster-1-host-${count.index}-ebs-sde"
    Project = var.project_id
    user = local.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_volume_attachment" "mapr-cluster-1-host-volume-attachment-sde" {
  count       = var.mapr_cluster_1_count
  device_name = "/dev/sde"
  volume_id   = aws_ebs_volume.mapr-cluster-1-host-ebs-volumes-sde.*.id[count.index]
  instance_id = aws_instance.mapr_cluster_1_hosts.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdf

resource "aws_ebs_volume" "mapr-cluster-1-host-ebs-volumes-sdf" {
  count             = var.mapr_cluster_1_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-mapr-cluster-1-host-${count.index}-ebs-sdf"
    Project = var.project_id
    user = local.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_volume_attachment" "mapr-cluster-1-host-volume-attachment-sdf" {
  count       = var.mapr_cluster_1_count
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mapr-cluster-1-host-ebs-volumes-sdf.*.id[count.index]
  instance_id = aws_instance.mapr_cluster_1_hosts.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}