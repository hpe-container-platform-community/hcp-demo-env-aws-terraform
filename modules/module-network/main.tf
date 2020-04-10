/******************* VPC ********************/

resource "aws_vpc" "main" {
  cidr_block  = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true
  # assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "${var.project_id}-vpc"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

/******************* Subnet ********************/

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_block
  availability_zone_id    = var.aws_zone_id
  map_public_ip_on_launch = true

  # ipv6_cidr_block = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)
  # assign_ipv6_address_on_creation = true

  tags = {
    Name = "${var.project_id}-subnet"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

/******************* Route Table ********************/

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # route {
  #   ipv6_cidr_block = "::/0"
  #   gateway_id = aws_internet_gateway.main.id
  # }

  tags = {
    Name = "${var.project_id}-default-route-table"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_default_route_table.main.id
}

/******************* Internet Gateway ********************/

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_id}-internet-gateway"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}