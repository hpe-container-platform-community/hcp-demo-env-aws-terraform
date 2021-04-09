#!/bin/bash 

set -e
set -u

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

pip3 install --quiet --upgrade --user hpecp

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
echo "Platform ID: $(hpecp license platform-id)"

set +u

# CLUSTER_ID="$1"  # FIRST ARGUMENT

# echo "${MASTER_IDS}"
# echo "${WORKER_IDS[@]}"

# if [[ $CLUSTER_ID =~ ^\/api\/v2\/k8scluster\/[0-9]$ ]]; 
# then
#   echo 
# else
#   echo "Usage: $0 /api/v2/k8scluster/[0-9]"
#   exit 1
# fi

echo -n "Enter aws_access_key_id: "
read -s AWS_ACCESS_KEY_ID
export AWS_ACCESS_KEY_ID
echo

echo -n "Enter aws_secret_access_key: "
read -s AWS_SECRET_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY
echo

BUCKET=${PROJECT_ID}-velero
VELERO_IAM_USER=${PROJECT_ID}-${USER}-velero

if aws s3api list-buckets | grep $BUCKET;
then
    read -p "Delete existing aws bucket $BUCKET? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
    aws s3 rb $BUCKET  --force
fi

if aws iam list-access-keys --user-name $VELERO_IAM_USER
then
   AccessKeyMetadata=$(aws iam list-access-keys --user-name $VELERO_IAM_USER)
   
   ACCESS_KEY_LEN=$(echo $AccessKeyMetadata | python3 -c 'import json,sys;obj=json.load(sys.stdin);print(len(obj["AccessKeyMetadata"]))')
   if [[ $ACCESS_KEY_LEN > 0 ]]; 
   then
       ACCESS_KEY_ID=$(echo $AccessKeyMetadata | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["AccessKeyMetadata"][0]["AccessKeyId"])')
       aws iam delete-access-key --access-key-id $ACCESS_KEY_ID --user-name $VELERO_IAM_USER
    fi
fi

if aws iam list-user-policies --user-name $VELERO_IAM_USER
then
   aws iam delete-user-policy --user-name $VELERO_IAM_USER --policy-name velero
fi

if aws iam list-users | grep $VELERO_IAM_USER
then
   aws iam delete-user --user $VELERO_IAM_USER
fi




if [[ "$REGION" == "us-east-1" ]];
then
    aws s3api create-bucket \
        --bucket $BUCKET \
        --region $REGION 
else
    aws s3api create-bucket \
        --bucket $BUCKET \
        --region $REGION \
        --create-bucket-configuration LocationConstraint=$REGION
fi

aws iam create-user --user-name $VELERO_IAM_USER

cat > velero-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}"
            ]
        }
    ]
}
EOF

aws iam put-user-policy \
  --user-name $VELERO_IAM_USER \
  --policy-name velero \
  --policy-document file://velero-policy.json
  
CREDENTIALS_VELERO=$(aws iam create-access-key --user-name $VELERO_IAM_USER)

AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS_VELERO | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["AccessKey"]["AccessKeyId"])')
AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS_VELERO | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["AccessKey"]["SecretAccessKey"])')

cat << EOF > credentials-velero
[default]
aws_access_key_id=$AWS_ACCESS_KEY_ID
aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
EOF

ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" ubuntu@$RDP_PUB_IP <<ENDSSH

    set -x

cat << EOF > credentials-velero
[default]
aws_access_key_id=$AWS_ACCESS_KEY_ID
aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
EOF

    if [[ ! -f velero-v1.5.4-linux-amd64.tar.gz ]];
    then
        wget -c https://github.com/vmware-tanzu/velero/releases/download/v1.5.4/velero-v1.5.4-linux-amd64.tar.gz
        tar xvzf velero-v1.5.4-linux-amd64.tar.gz
        sudo cp velero-v1.5.4-linux-amd64/velero /usr/local/bin/
    fi
    
    CLUSTERNAME=c1
    KUBECONFIG=~/kubeconfig_c1.conf
    ./get_admin_kubeconfig.sh \$CLUSTERNAME > \$KUBECONFIG
    
    export KUBECONFIG=~/kubeconfig_c1.conf
    
    velero install \
        --provider aws \
        --plugins velero/velero-plugin-for-aws:v1.2.0 \
        --bucket $BUCKET \
        --backup-location-config region=$REGION \
        --snapshot-location-config region=$REGION \
        --secret-file ./credentials-velero \
        --kubeconfig \$KUBECONFIG
    
    if ! grep 'source <(velero completion bash)' ~/.bashrc;
    then
        echo 'source <(velero completion bash)' >>~/.bashrc
    fi
    
ENDSSH

