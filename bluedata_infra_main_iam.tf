resource "aws_iam_user" "iam_user" {
  name = "${var.project_id}-iam-user-${random_uuid.deployment_uuid.result}"

  tags = {
    Name = "${var.project_id}-iam-user"
    Project = "${var.project_id}"
    user = "${var.user}"
    deployment_uuid = "${random_uuid.deployment_uuid.result}"
  }
}

resource "aws_iam_access_key" "start_stop_ec2_instances_access_key" {
  user = aws_iam_user.iam_user.name
}

data "aws_caller_identity" "current" {}

resource "aws_iam_user_policy" "start_stop_ec2_instances" {
  name = "${var.project_id}-start-stop-ec2-instances"
  user = aws_iam_user.iam_user.name

  policy = <<-EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "StartStopIfTags",
              "Effect": "Allow",
              "Action": [
                  "ec2:StartInstances",
                  "ec2:StopInstances",
                  "ec2:DescribeTags"
              ],
              "Resource": "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*",
              "Condition": {
                  "StringEquals": {
                      "ec2:ResourceTag/Project": "${var.project_id}",
                      "ec2:ResourceTag/user": "${var.user}"
                  }
              }
          }
      ]
  }
  EOF
}

resource "aws_iam_user_policy" "describe_ec2_instances" {
  name = "${var.project_id}-describe-ec2-instances"
  user = aws_iam_user.iam_user.name

  policy = <<-EOF
  {
      "Version": "2012-10-17",
      "Statement": [
         {
              "Sid": "GetStatusOfInstances",
              "Effect": "Allow",
              "Action": [
                  "ec2:DescribeInstanceStatus",
                  "ec2:DescribeInstances"
              ],
              "Resource": "*"
          }
      ]
  }
  EOF
}


resource "aws_iam_user_policy" "allow_from_my_ip" {
  name = "${var.project_id}-allow-from-my-ip"
  user = aws_iam_user.iam_user.name

  policy = <<-EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "ReplaceNetworkAclEntry",
              "Effect": "Allow",
              "Action": [
                  "ec2:ReplaceNetworkAclEntry",
                  "ec2:AuthorizeSecurityGroupIngress"
              ],
              "Resource": "*",
              "Condition": {
                "ArnEquals" : { "aws:PrincipalArn" : [ "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.iam_user.name}" ] } 
              }
          }
      ]
  }
  EOF
}

resource "local_file" "non_terraform_user_scripts" {

  filename = "${path.module}/generated/non_terraform_user_scripts.txt"
  content =  <<-EOF

    # An IAM user was created for this script: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.iam_user.name}"
    # The IAM user only has permissions to run this script.

    # The ACCESS and SECRET key for the IAM user are below:

    AWS_ACCESS_KEY="${aws_iam_access_key.start_stop_ec2_instances_access_key.id}"
    AWS_SECRET_KEY="${aws_iam_access_key.start_stop_ec2_instances_access_key.secret}"

    # Start EC2 instances - after starting your instances, run the command below to check for the new 
    aws --region ${var.region} --profile ${var.profile} ec2 start-instances --instance-ids ${local.instance_ids}

    # Stop EC2 instances 
    aws --region ${var.region} --profile ${var.profile} ec2 stop-instances --instance-ids ${local.instance_ids}

    # EC2 instances status
    aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${local.instance_ids} --include-all-instances --output table --query "InstanceStatuses[*].{ID:InstanceId,State:InstanceState.Name}"

    # RDP Server Public IP Address and Password (RDP Username = ubuntu)
    aws --region ${var.region} --profile ${var.profile} ec2 describe-instances --instance-ids ${module.rdp_server_linux.instance_id != null ? module.rdp_server_linux.instance_id : ""} --output json --query "Reservations[*].Instances[*].[PublicIpAddress,InstanceId]"

    # Add My IP to Network ACL
    aws ec2 --region ${var.region} --profile default create-network-acl-entry \
        --network-acl-id ${module.network.network_acl_id} \
        --cidr-block "$(curl -s http://ifconfig.me/ip)/32" \
        --ingress \
        --protocol -1 \
        --rule-action allow \
        --rule-number 110

    # if the above fails, try the following:  
    aws ec2 --region ${var.region} --profile default replace-network-acl-entry \
        --network-acl-id ${module.network.network_acl_id} \
        --cidr-block "$(curl -s http://ifconfig.me/ip)/32" \
        --ingress \
        --protocol -1 \
        --rule-action allow \
        --rule-number 110

    # Add My IP to security group
    aws ec2 --region ${var.region} --profile default authorize-security-group-ingress \
        --group-id ${module.network.sg_allow_all_from_specified_ips} \
        --protocol all \
        --port -1 \
        --cidr "$(curl -s http://ifconfig.me/ip)/32"

  EOF

}
