# Don't do anything with the default sg except add tags
resource "aws_default_security_group" "main" {
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_id}-default-security-group"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_security_group" "main" {
  vpc_id      = aws_vpc.main.id
  name        = "main"
  description = "main"

  tags = {
    Name = "${var.project_id}-default-security-group"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_security_group_rule" "internal_host_to_host_access" {
  security_group_id = aws_security_group.main.id
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  self            = true
}

resource "aws_security_group_rule" "return_traffic" {
  security_group_id = aws_security_group.main.id
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
}

// allow all traffic from specified ips

locals {
  full_access_sg_ips = concat([var.client_cidr_block], var.additional_client_ip_list)
}

resource "aws_security_group" "allow_all_from_specified_ips" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_all_from_specified_ips"
  description = "allow_all_from_specified_ips"
  depends_on = [ aws_vpc.main ]

  tags = {
    Name = "${var.project_id}-allow-all-from-specified-ips-security-group"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  ingress {
    protocol   = "-1"
    cidr_blocks = local.full_access_sg_ips
    from_port  = 0
    to_port    = 0
  }
}

// allow ssh from world security group

resource "aws_security_group" "allow_ssh_from_world" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_ssh_from_world"
  description = "allow_ssh_from_world - disabled"
  depends_on = [ aws_vpc.main ]

  tags = {
    Name = "${var.project_id}-allow-ssh-from-world-security-group"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  // DISABLED - uncomment to enable, but don't do this without good reason
  //            due to security exposure

  /*
  ingress {
    protocol   = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port  = 22
    to_port    = 22
  }
  */
}

// allow rdp from world security group

resource "aws_security_group" "allow_rdp_from_world" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_rdp_from_world"
  description = "allow_rdp_from_world - disabled"
  depends_on = [ aws_vpc.main ]

  tags = {
    Name = "${var.project_id}-allow-rdp-from-world-security-group"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  // DISABLED - uncomment to enable, but don't do this without good reason
  //            due to security exposure
  
  /*
  ingress {
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port   = 3389
    to_port     = 3389
  }
  */
}