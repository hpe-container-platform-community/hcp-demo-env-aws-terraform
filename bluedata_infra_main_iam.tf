resource "aws_iam_user" "iam_user" {
  name = "${var.project_id}-iam-user"

  tags = {
    Name = "${var.project_id}-iam-user"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}

resource "aws_iam_access_key" "start_stop_ec2_instances_access_key" {
  user = aws_iam_user.iam_user.name
}

data "aws_caller_identity" "current" {}

output "iam_access_key" {
  value = aws_iam_access_key.start_stop_ec2_instances_access_key.id
}

output "iam_secret" {
  value =  aws_iam_access_key.start_stop_ec2_instances_access_key.secret
}

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
                  "ec2:ReplaceNetworkAclEntry"
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
