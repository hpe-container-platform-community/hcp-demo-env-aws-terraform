resource "aws_instance" "workers" {
  count                  = var.worker_count
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
    Name = "${var.project_id}-instance-worker-${count.index + 1}"
    Project = var.project_id
    user = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "null_resource" "yum_update_workers" {
  count = var.worker_count

  connection {
    type        = "ssh"
    user        = "centos"
    host        = aws_instance.workers.*.public_ip[count.index]
    private_key = file(var.ssh_prv_key_path)
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [ "sudo yum update -y -q" ]
  }
}

# /dev/sdb

resource "aws_ebs_volume" "worker-ebs-volumes-sdb" {
  count             = var.worker_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-worker-${count.index + 1}-ebs-sdb"
    Project = var.project_id
    user = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_volume_attachment" "worker-volume-attachment-sdb" {
  count       = var.worker_count
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.worker-ebs-volumes-sdb.*.id[count.index]
  instance_id = aws_instance.workers.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdc

resource "aws_ebs_volume" "worker-ebs-volumes-sdc" {
  count             = var.worker_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-worker-${count.index + 1}-ebs-sdc"
    Project = var.project_id
    user = var.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_volume_attachment" "worker-volume-attachment-sdc" {
  count       = var.worker_count
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.worker-ebs-volumes-sdc.*.id[count.index]
  instance_id = aws_instance.workers.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}
