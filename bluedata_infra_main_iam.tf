resource "aws_iam_user" "iam_user" {

  count = var.create_iam_user ? 1 : 0
  name = "${var.project_id}-iam-user-${random_uuid.deployment_uuid.result}"

  tags = {
    Name = "${var.project_id}-iam-user"
    Project = var.project_id
    user = local.user
    deployment_uuid = random_uuid.deployment_uuid.result
  }
}

resource "aws_iam_access_key" "start_stop_ec2_instances_access_key" {
  count = var.create_iam_user ? 1 : 0
  user = aws_iam_user.iam_user[count.index].name
}

//data "aws_caller_identity" "current" {}


locals {
  instance_arns = jsonencode(compact(flatten([
       [ module.nfs_server.instance_arn ],
       [ module.ad_server.instance_arn ],
       [ module.rdp_server_linux.instance_arn ],
       [ module.controller.arn ],
       [ module.gateway.arn ],
       [ aws_instance.workers.*.arn ],
       [ aws_instance.workers_gpu.*.arn ],
       [ aws_instance.mapr_cluster_1_hosts.*.arn ],
       [ aws_instance.mapr_cluster_2_hosts.*.arn ]
     ])
  ))
}

# output "instance_arns" {
#   value = local.instance_arns
# }

resource "aws_iam_user_policy" "start_stop_ec2_instances" {
  count = var.create_iam_user ? 1 : 0
  name = "${var.project_id}-policy"
  user = aws_iam_user.iam_user[count.index].name

  policy = <<-EOF
  {
      "Version": "2012-10-17",
      "Statement": [
        {
            "Sid": "StartStopInstances",
            "Effect": "Allow",
            "Action": [
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": ${local.instance_arns}
        },
        {
            "Sid": "DescribeResources",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeInstances",
                "ec2:DescribeTags",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EditNacl",
            "Effect": "Allow",
            "Action": [
                "ec2:ReplaceNetworkAclEntry",
                "ec2:CreateNetworkAclEntry"
            ],
            "Resource": "${module.network.network_acl_arn}"
        },
        {
            "Sid": "EditSG",
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress"
            ],
            "Resource": "${module.network.vpc_main_arn}",
            "Condition": {
              "ArnEquals" : { 
                "aws:PrincipalArn" : [ 
                  "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.iam_user[count.index].name}"
                ] 
              } 
            }
        }
      ]
  }
  EOF
}

resource "local_file" "non_terraform_user_scripts_update_firewall" {
  count = var.create_iam_user ? 1 : 0
  filename = "${path.module}/generated/non_terraform_user/update_firewall_script.sh"
  content =  <<-EOF
    #!/bin/bash

    set -e

    # An IAM user was created for this script: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.iam_user[count.index].name}"
    # The IAM user only has permissions to run this script.

    # The ACCESS and SECRET key for the IAM user are below:

    export AWS_ACCESS_KEY_ID="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].id}"
    export AWS_SECRET_ACCESS_KEY="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].secret}"
    export AWS_DEFAULT_REGION="${var.region}"
    
    MY_IP="$(curl -s http://ipinfo.io/ip)/32"

    # Add My IP to Network ACL

    RULE_110=$(aws ec2 --region ${var.region} \
      --profile default \
      describe-network-acls \
      --network-acl-id ${module.network.network_acl_id} \
      --query 'NetworkAcls[*].Entries[?RuleNumber == `110` && Egress ==`false` ] | [?length(@) == `1`] | []')

    echo "Query result for RuleNumber=110, Ingress:"
    echo "$RULE_110"

    if [[ "$${RULE_110}" == "[]" ]]; then
        # Rule 110 doesn't exist so create it
        aws ec2 --region ${var.region} --profile default create-network-acl-entry \
            --network-acl-id ${module.network.network_acl_id} \
            --cidr-block "$${MY_IP}" \
            --ingress \
            --protocol -1 \
            --rule-action allow \
            --rule-number 110
    else
        # Rule 110 does exist so replace it
        aws ec2 --region ${var.region} --profile default replace-network-acl-entry \
            --network-acl-id ${module.network.network_acl_id} \
            --cidr-block "$${MY_IP}" \
            --ingress \
            --protocol -1 \
            --rule-action allow \
            --rule-number 110
    fi

    SG=$(aws ec2 --region ${var.region} \
            --profile default \
            describe-security-groups \
            --group-id ${module.network.security_group_allow_all_from_client_ip} \
            --query 'SecurityGroups[*].IpPermissions[*].IpRanges[*].CidrIp | [] | [] | [? contains(@, ` "$${MY_IP}"`)] | [?length(@) == `1`]')

    if [[ "$${SG}" != "[]" ]]; then
      # Add My IP to security group
      aws ec2 --region ${var.region} --profile default authorize-security-group-ingress \
          --group-id ${module.network.sg_allow_all_from_specified_ips} \
          --protocol all \
          --port -1 \
          --cidr "$${MY_IP}"
    fi
  EOF
}

resource "local_file" "non_terraform_user_scripts_start_instances" {
  count = var.create_iam_user ? 1 : 0
  filename = "${path.module}/generated/non_terraform_user/start_instances.sh"
  content =  <<-EOF
    #!/bin/bash

    set -e

    # An IAM user was created for this script: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.iam_user[count.index].name}"
    # The IAM user only has permissions to run this script.

    # The ACCESS and SECRET key for the IAM user are below:

    export AWS_ACCESS_KEY_ID="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].id}"
    export AWS_SECRET_ACCESS_KEY="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].secret}"
    export AWS_DEFAULT_REGION="${var.region}"

    # Start EC2 instances - after starting your instances, run the command below to check for the new 
    aws --region ${var.region} --profile ${var.profile} ec2 start-instances --instance-ids ${local.instance_ids}
  EOF
}

resource "local_file" "non_terraform_user_scripts_stop_instances" {
  count = var.create_iam_user ? 1 : 0
  filename = "${path.module}/generated/non_terraform_user/stop_instances.sh"
  content =  <<-EOF
    #!/bin/bash

    set -e

    # An IAM user was created for this script: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.iam_user[count.index].name}"
    # The IAM user only has permissions to run this script.

    # The ACCESS and SECRET key for the IAM user are below:

    export AWS_ACCESS_KEY_ID="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].id}"
    export AWS_SECRET_ACCESS_KEY="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].secret}"
    export AWS_DEFAULT_REGION="${var.region}"
    
    # Stop EC2 instances 
    aws --region ${var.region} --profile ${var.profile} ec2 stop-instances --instance-ids ${local.instance_ids}
  EOF
}

resource "local_file" "non_terraform_user_scripts_status_instances" {
  count = var.create_iam_user ? 1 : 0
  filename = "${path.module}/generated/non_terraform_user/instance_status.sh"
  content =  <<-EOF
    #!/bin/bash

    set -e

    # An IAM user was created for this script: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.iam_user[count.index].name}"
    # The IAM user only has permissions to run this script.

    # The ACCESS and SECRET key for the IAM user are below:

    export AWS_ACCESS_KEY_ID="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].id}"
    export AWS_SECRET_ACCESS_KEY="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].secret}"
    export AWS_DEFAULT_REGION="${var.region}"
    
    # EC2 instances status
    aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${local.instance_ids} --include-all-instances --output table --query "InstanceStatuses[*].{ID:InstanceId,State:InstanceState.Name}"
  EOF
}

resource "local_file" "non_terraform_user_scripts_rdp_info" {
  count = var.create_iam_user ? 1 : 0
  filename = "${path.module}/generated/non_terraform_user/rdp_info.sh"
  content =  <<-EOF
    #!/bin/bash

    set -e

    # An IAM user was created for this script: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.iam_user[count.index].name}"
    # The IAM user only has permissions to run this script.

    # The ACCESS and SECRET key for the IAM user are below:

    export AWS_ACCESS_KEY_ID="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].id}"
    export AWS_SECRET_ACCESS_KEY="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].secret}"
    export AWS_DEFAULT_REGION="${var.region}"
    
    # RDP Server Info
    IFS=,
    INFO=($(aws --region ${var.region} --profile ${var.profile} ec2 describe-instances --instance-ids ${module.rdp_server_linux.instance_id != null ? module.rdp_server_linux.instance_id : ""} --output text --query 'Reservations[*].Instances[*].[PublicIpAddress,InstanceId] | [][] | join(`,`, @)'))
    PUB_IP=$${INFO[0]}
    PASSWD=$${INFO[1]}

    echo RDP Endpoint Details
    echo --------------------
    echo Username: ubuntu
    echo Password: $${PASSWD}
    echo IP ADDR:  $${PUB_IP}
    echo WEB URL:  https://$${PUB_IP}
  EOF
}

resource "local_file" "non_terraform_user_scripts_controller_info" {
  count = var.create_iam_user ? 1 : 0
  filename = "${path.module}/generated/non_terraform_user/controller_info.sh"
  content =  <<-EOF
    #!/bin/bash

    set -e

    # An IAM user was created for this script: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${aws_iam_user.iam_user[count.index].name}"
    # The IAM user only has permissions to run this script.

    # The ACCESS and SECRET key for the IAM user are below:

    export AWS_ACCESS_KEY_ID="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].id}"
    export AWS_SECRET_ACCESS_KEY="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].secret}"
    export AWS_DEFAULT_REGION="${var.region}"
    
    # Controller Server Public IP Address 
    aws --region ${var.region} --profile ${var.profile} ec2 describe-instances --instance-ids ${module.controller.id != null ? module.controller.id : ""} --output json --query "Reservations[*].Instances[*].[PublicIpAddress]"
  EOF
}

resource "local_file" "non_terraform_user_scripts_variables" {
  count = var.create_iam_user ? 1 : 0
  filename = "${path.module}/generated/non_terraform_user/variables.sh"
  content =  <<-EOF
    export AWS_ACCESS_KEY_ID="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].id}"
    export AWS_SECRET_ACCESS_KEY="${aws_iam_access_key.start_stop_ec2_instances_access_key[count.index].secret}"
    export AWS_REGION="${var.region}"
    export RDP_INSTANCE_ID=${module.rdp_server_linux.instance_id != null ? module.rdp_server_linux.instance_id : ""}
    export CONTROLLER_INSTANCE_ID=${module.controller.id != null ? module.controller.id : ""}
    export ALL_INSTANCE_IDS="${local.instance_ids}"
    export NACL_ID=${module.network.network_acl_id}
    export SG_ID=${module.network.sg_allow_all_from_specified_ips}
    export INSTALL_WITH_SSL=${var.install_with_ssl}
  EOF
}
