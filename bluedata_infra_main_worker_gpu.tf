locals {
  gpu_worker_count = 0
  gpu_worker_instance_type = "g4dn.xlarge" # change this for your region
  gpu_worker_has_disk_for_df = false # create /dev/sdc for data fabric - true or false 

  ## don't change below
  gpu_worker_instance_type_error = "gpu_worker_instance_type '${local.gpu_worker_instance_type}' is invalid for Region '${var.region}'"
}

########## ASSERT GPU WORKER INSTANCE TYPE IS VALID FOR AZ ##########

data "aws_ec2_instance_type_offerings" "gpu_worker_instance_types" {
  filter {
    name   = "instance-type"
    values = [ "${local.gpu_worker_instance_type}" ]
  }
  filter {
    name   = "location"
    values = [ "${var.region}" ]
  }
  location_type = "region"
}

resource "null_resource" "gpu_worker_instance_type_validation" {
  count = (local.gpu_worker_count > 0 && length(data.aws_ec2_instance_type_offerings.gpu_worker_instance_types.instance_types) == 0) ? 1 : 0

  provisioner "local-exec" {
    command     = "false"
    interpreter = [ "bash", "-c", "(tput setaf 1 && echo \"${local.gpu_worker_instance_type_error}\" && tput sgr0 && false)"]
  }
}

########## END ASSERTION ##########

resource "aws_instance" "workers_gpu" {
  count                  = local.gpu_worker_count
  ami                    = var.EC2_CENTOS7_AMIS[var.region]
  instance_type          = local.gpu_worker_instance_type
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
    Name = "${var.project_id}-instance-worker-gpu-${count.index + 1}"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }

  depends_on = [
    null_resource.gpu_worker_instance_type_validation,
  ]
}

resource "null_resource" "yum_update_workers_gpu" {
  count = local.gpu_worker_count

  connection {
    type        = "ssh"
    user        = "centos"
    host        = aws_instance.workers_gpu.*.public_ip[count.index]
    private_key = file("${var.ssh_prv_key_path}")
    agent       = false
  }

  provisioner "remote-exec" {
    inline = [ "sudo yum update -y -q" ]
  }
}

# /dev/sdb

resource "aws_ebs_volume" "worker-gpu-ebs-volumes-sdb" {
  count             = local.gpu_worker_count
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-worker-gpu-${count.index + 1}-ebs-sdb"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

resource "aws_volume_attachment" "worker-gpu-volume-attachment-sdb" {
  count       = local.gpu_worker_count
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.worker-gpu-ebs-volumes-sdb.*.id[count.index]
  instance_id = aws_instance.workers_gpu.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

# /dev/sdc

resource "aws_ebs_volume" "worker-gpu-ebs-volumes-sdc" {
  count             = local.gpu_worker_has_disk_for_df == true ?   local.gpu_worker_count : 0
  availability_zone = var.az
  size              = 1024
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-worker-gpu-${count.index + 1}-ebs-sdc"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

resource "aws_volume_attachment" "worker-gpu-volume-attachment-sdc" {
  count       = local.gpu_worker_has_disk_for_df == true ? local.gpu_worker_count : 0
  device_name = "/dev/sdc"
  volume_id   = aws_ebs_volume.worker-gpu-ebs-volumes-sdc.*.id[count.index]
  instance_id = aws_instance.workers_gpu.*.id[count.index]

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}
