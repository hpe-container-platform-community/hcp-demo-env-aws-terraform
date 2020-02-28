# Don't do anything with the default network acl except add tags
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.main.default_network_acl_id
  subnet_ids = [ aws_subnet.main.id ]

  tags = {
    Name = "${var.project_id}-default-network-acl"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_network_acl" "main" {
  vpc_id      = aws_vpc.main.id
  subnet_ids = [ aws_subnet.main.id ]

  tags = {
    Name = "${var.project_id}-network-acl"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_network_acl_rule" "allow_all_from_client_ip" {
  # allow client machine to have full access to all hosts
  network_acl_id = aws_network_acl.main.id
  rule_number = "100"
  egress      = false
  protocol    = "-1"
  rule_action = "allow"
  cidr_block  = var.client_cidr_block
  from_port   = 0
  to_port     = 0
}

resource "aws_network_acl_rule" "allow_internet_access_from_instances" {
  # allow internet access from instances 
  network_acl_id = aws_network_acl.main.id
  rule_number = "110"
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
  from_port   = 1024
  to_port     = 65535
}

resource "aws_network_acl_rule" "allow_ssh" {
  network_acl_id = aws_network_acl.main.id
  rule_number = "120"
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
  from_port   = 22
  to_port     = 22
}

resource "aws_network_acl_rule" "allow_rdp" {
  network_acl_id = aws_network_acl.main.id
  rule_number = "130"
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
  from_port   = 3389
  to_port     = 3389
}

// egress

resource "aws_network_acl_rule" "allow_response_traffic_from_hosts_to_internet" {
  # allow internet access from instances 
  network_acl_id = aws_network_acl.main.id
  rule_number = "120"
  egress      = true
  protocol    = "-1"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
  from_port   = 0
  to_port     = 0
}