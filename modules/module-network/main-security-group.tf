// default security group

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

// allow all traffic from client machine

resource "aws_security_group" "allow_all_from_client_ip" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_all_from_client_ip"
  description = "allow_all_from_client_ip"
  depends_on = [ aws_vpc.main ]

  tags = {
    Name = "${var.project_id}-allow-ssh-from-world-security-group"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  ingress {
    protocol   = "-1"
    cidr_blocks = [ var.client_cidr_block ]
    from_port  = 0
    to_port    = 0
  }
}

// allow ssh from world security group

resource "aws_security_group" "allow_ssh_from_world" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_ssh_from_world"
  description = "allow_ssh_from_world"
  depends_on = [ aws_vpc.main ]

  tags = {
    Name = "${var.project_id}-allow-ssh-from-world-security-group"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  ingress {
    protocol   = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port  = 22
    to_port    = 22
  }
}

// allow rdp from world security group

resource "aws_security_group" "allow_rdp_from_world" {
  vpc_id      = aws_vpc.main.id
  name        = "allow_rdp_from_world"
  description = "allow_rdp_from_world"
  depends_on = [ aws_vpc.main ]

  tags = {
    Name = "${var.project_id}-allow-rdp-from-world-security-group"
    Project = "${var.project_id}"
    user = "${var.user}"
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port   = 3389
    to_port     = 3389
  }
}