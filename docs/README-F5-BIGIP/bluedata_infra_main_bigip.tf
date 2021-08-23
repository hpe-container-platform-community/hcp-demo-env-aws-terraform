resource "aws_network_interface" "bigip_nic_1" {
  subnet_id       = module.network.subnet_main_id
  security_groups = [
    module.network.security_group_allow_all_from_client_ip,
    module.network.security_group_main_id
  ]
}

resource "aws_network_interface" "bigip_nic_2" {
  subnet_id       = module.network.subnet_main_id
  security_groups = [
    module.network.security_group_allow_all_from_client_ip,
    module.network.security_group_main_id
  ]
}

resource "aws_network_interface" "bigip_nic_3" {
  subnet_id       = module.network.subnet_main_id
  security_groups = [
    module.network.security_group_allow_all_from_client_ip,
    module.network.security_group_main_id
  ]
}

resource "aws_eip" "bigip_eip" {
  vpc = true
  tags = {
    Name = "${var.project_id}-eip-bigip"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_eip_association" "eip_assoc_bigip" {
  allocation_id = aws_eip.bigip_eip.id
  network_interface_id = aws_network_interface.bigip_nic_1.id
}

resource "aws_instance" "bigip" {

  # Find AMI for regions outside of Oregaon, here: 
  # https://aws.amazon.com/marketplace/server/configuration?productId=8e1217d4-a046-4cdf-894e-e38175bae37f&ref_=psb_cfg_continue 

  ami                    = "ami-0b6bb8289ee2d28d0"
  instance_type          = "m4.xlarge"
  availability_zone      = var.az

  key_name               = aws_key_pair.main.key_name

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  network_interface {
     network_interface_id = aws_network_interface.bigip_nic_1.id
     device_index = 0
  }
  network_interface {
     network_interface_id = aws_network_interface.bigip_nic_2.id
     device_index = 1
  }
  network_interface {
     network_interface_id = aws_network_interface.bigip_nic_3.id
     device_index = 2
  }

  tags = {
    Name = "${var.project_id}-instance-bigip"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

# /dev/sdb

resource "aws_ebs_volume" "bigip-ebs-volumes-sdb" {
  availability_zone = var.az
  size              = 500
  type              = "gp2"

  tags = {
    Name = "${var.project_id}-bigip-ebs-sdb"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

resource "aws_volume_attachment" "bigip-volume-attachment-sdb" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.bigip-ebs-volumes-sdb.id
  instance_id = aws_instance.bigip.id

  # hack to allow `terraform destroy ...` to work: https://github.com/hashicorp/terraform/issues/2957
  force_detach = true
}

output "bigip_public_ip" {
  value = "${aws_eip.bigip_eip.public_ip}"
}

output "bigip_private_ip_1" {
  value = "${aws_network_interface.bigip_nic_1.private_ip}"
}
output "bigip_private_ip_2" {
  value = "${aws_network_interface.bigip_nic_2.private_ip}"
}
output "bigip_private_ip_3" {
  value = "${aws_network_interface.bigip_nic_3.private_ip}"
}
