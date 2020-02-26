resource "aws_default_security_group" "main" {
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_id}-default-security-group"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_security_group_rule" "allow_all_from_client_machine" {
  security_group_id = aws_default_security_group.main.id
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = [ var.client_cidr_block ]
}

resource "aws_security_group_rule" "internal_host_to_host_access" {
  security_group_id = aws_default_security_group.main.id
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  self            = true
}

resource "aws_security_group_rule" "allow_ssh" {
  security_group_id = aws_default_security_group.main.id
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = [ var.allow_ssh_from_world == true ? "0.0.0.0/0" : var.client_cidr_block ]
}

resource "aws_security_group_rule" "allow_rdp" {
  security_group_id = aws_default_security_group.main.id
  type            = "ingress"
  from_port       = 3389
  to_port         = 3389
  protocol        = "tcp"
  cidr_blocks     = [ var.allow_ssh_from_world == true ? "0.0.0.0/0" : var.client_cidr_block ]
}

resource "aws_security_group_rule" "allow_all_outgoing_traffic" {
  security_group_id = aws_default_security_group.main.id
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = [ "0.0.0.0/0" ]
}