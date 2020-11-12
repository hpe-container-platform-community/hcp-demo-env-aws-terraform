locals {
  cluster_name = random_uuid.deployment_uuid.result
}

resource "aws_subnet" "main2" {
  vpc_id                  = module.network.vpc_main_id
  cidr_block              = var.eks_subnet2_cidr_block
  availability_zone       = "${var.region}${var.eks_subnet2_az_suffix}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_id}-eks-subnet2"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = local.cluster_name
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "main3" {
  vpc_id                  = module.network.vpc_main_id
  cidr_block              = var.eks_subnet3_cidr_block
  availability_zone       = "${var.region}${var.eks_subnet3_az_suffix}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_id}-eks-subnet3"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = local.cluster_name
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "main2" {
  subnet_id      = aws_subnet.main2.id
  route_table_id = module.network.route_main_id
}

resource "aws_route_table_association" "main3" {
  subnet_id      = aws_subnet.main3.id
  route_table_id = module.network.route_main_id
}

resource "aws_network_acl" "main-eks" {
  vpc_id      = module.network.vpc_main_id
  subnet_ids = [       
    aws_subnet.main2.id, 
    aws_subnet.main3.id
    ]

  tags = {
    Name = "${var.project_id}-eks-network-acl"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = local.cluster_name  
  }
}

resource "aws_network_acl_rule" "eks_allow_all_from_client_ips" {
  # allow client machine to have full access to all hosts
  network_acl_id = aws_network_acl.main-eks.id

  rule_number = 100
  egress      = false
  protocol    = "-1"
  rule_action = "allow"
  cidr_block  = var.client_cidr_block
  from_port   = 0
  to_port     = 0
}

resource "aws_network_acl_rule" "eks_allow_all_from_specific_ips" {
  # allow specified machines to have full access to all hosts
  network_acl_id = aws_network_acl.main-eks.id

  count       = length(var.additional_client_ip_list)
  rule_number = 110 + count.index
  egress      = false
  protocol    = "-1"
  rule_action = "allow"
  cidr_block  = element(var.additional_client_ip_list, count.index)
  from_port   = 0
  to_port     = 0
}

resource "aws_network_acl_rule" "eks_allow_internet_access_from_instances" {
  # allow internet access from instances 
  network_acl_id = aws_network_acl.main-eks.id
  rule_number = "150"
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
  from_port   = 1024
  to_port     = 65535
}

resource "aws_network_acl_rule" "eks_allow_ssh" {
  network_acl_id = aws_network_acl.main-eks.id
  rule_number = "160"
  egress      = false
  protocol    = "tcp"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
  from_port   = 22
  to_port     = 22
}

resource "aws_network_acl_rule" "eks_allow_all_in_subnet" {
  network_acl_id = aws_network_acl.main-eks.id
  rule_number = "171"
  egress      = false
  protocol    = "-1"
  rule_action = "allow"
  cidr_block  = var.vpc_cidr_block
  from_port   = 0
  to_port     = 0
}

// egress

resource "aws_network_acl_rule" "eks_allow_response_traffic_from_hosts_to_internet" {
  # allow internet access from instances 
  network_acl_id = aws_network_acl.main-eks.id
  rule_number = "120"
  egress      = true
  protocol    = "-1"
  rule_action = "allow"
  cidr_block  = "0.0.0.0/0"
  from_port   = 0
  to_port     = 0
}



resource "aws_eks_cluster" "example" {
  count = var.create_eks_cluster ? 1 : 0
  name     = local.cluster_name
  role_arn = aws_iam_role.example[count.index].arn

  vpc_config {
    subnet_ids = [
      aws_subnet.main2.id, 
      aws_subnet.main3.id
    ]
    security_group_ids = [
      module.network.security_group_allow_all_from_client_ip,
      module.network.security_group_main_id
    ]
    endpoint_private_access = true
    endpoint_public_access = false
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
  ]

  tags = {
    Name = "${var.project_id}-eks"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = local.cluster_name
  }
}


resource "aws_eks_node_group" "example" {
  count = var.create_eks_cluster ? 1 : 0
  cluster_name    = aws_eks_cluster.example[count.index].name
  node_group_name = random_uuid.deployment_uuid.result
  node_role_arn   = aws_iam_role.eks-node-group-example[count.index].arn
  subnet_ids      = [
    aws_subnet.main2.id, 
    aws_subnet.main3.id
    ]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]
}

data "aws_eks_cluster_auth" "example" {
  count = var.create_eks_cluster ? 1 : 0
  name = local.cluster_name
}

// Eks policy

resource "aws_iam_role" "example" {
  count = var.create_eks_cluster ? 1 : 0
  name = "eks-cluster-${local.cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  count = var.create_eks_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example[count.index].name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "example-AmazonEKSVPCResourceController" {
  count = var.create_eks_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.example[count.index].name
}

/// worker policy

resource "aws_iam_role" "eks-node-group-example" {
  count = var.create_eks_cluster ? 1 : 0
  name = "eks-node-group-${local.cluster_name}"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  count = var.create_eks_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node-group-example[count.index].name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  count = var.create_eks_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node-group-example[count.index].name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  count = var.create_eks_cluster ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node-group-example[count.index].name
}

/// outputs

output "eks-server-url" {
  value = var.create_eks_cluster ? aws_eks_cluster.example[0].endpoint : ""
}

output "eks-ca-certificate" {
  value = var.create_eks_cluster ? aws_eks_cluster.example[0].certificate_authority[0].data : ""
}

output "eks-bearer-token" {
  value = var.create_eks_cluster ? base64encode(data.aws_eks_cluster_auth.example[0].token) : ""
}