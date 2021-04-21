#!/bin/bash

exec > >(tee -i generated/log-$(basename $0).txt)
exec 2>&1

set -e
set -u
set -o pipefail

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

set +u

MASTER_IDS="${@:1:1}"  # FIRST ARGUMENT
WORKER_IDS=("${@:2}")  # REMAINING ARGUMENTS

if [[ $MASTER_IDS =~ ^\/api\/v2\/worker\/k8shost\/[0-9]*$ ]] && [[ ${WORKER_IDS[0]} =~ ^\/api\/v2\/worker\/k8shost\/[0-9]*$ ]]; 
then
   echo "Running script: $0 $@"
else
   echo "Usage: $0 /api/v2/worker/k8shost/[0-9] /api/v2/worker/k8shost/[0-9] [ ... /api/v2/worker/k8shost/NNN ]"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

pip3 install --quiet --upgrade --user hpecp

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
echo "Platform ID: $(hpecp license platform-id)"

K8S_CLUSTER_NAME=kfcluster

MLFLOW_CLUSTER_NAME=mlflow
echo MLFLOW_CLUSTER_NAME=$MLFLOW_CLUSTER_NAME

AD_SERVER_PRIVATE_IP=$AD_PRV_IP
echo AD_SERVER_PRIVATE_IP=$AD_SERVER_PRIVATE_IP

K8S_HOST_CONFIG="$(echo $MASTER_IDS | sed 's/ /:master,/g'):master,$(echo ${WORKER_IDS[@]} | sed 's/ /:worker,/g'):worker"
echo K8S_HOST_CONFIG=$K8S_HOST_CONFIG

set -u

K8S_VERSION=$(hpecp k8scluster k8s-supported-versions --major-filter 1 --minor-filter 18 --output text)
echo K8S_VERSION=$K8S_VERSION

EXTERNAL_GROUPS=$(echo '["CN=AD_ADMIN_GROUP,CN=Users,DC=samdom,DC=example,DC=com","CN=AD_MEMBER_GROUP,CN=Users,DC=samdom,DC=example,DC=com"]' | sed s/AD_ADMIN_GROUP/${AD_ADMIN_GROUP}/g | sed s/AD_MEMBER_GROUP/${AD_MEMBER_GROUP}/g)

echo "Creating k8s cluster with version ${K8S_VERSION} and addons=[kubeflow,picasso-compute] | timeout=1800s"
CLUSTER_ID=$(hpecp k8scluster create \
  --name $K8S_CLUSTER_NAME \
  --k8s-version "$K8S_VERSION" \
  --k8shosts-config "$K8S_HOST_CONFIG" \
  --addons '["kubeflow","picasso-compute"]' \
  --ext_id_svr_bind_pwd "5ambaPwd@" \
  --ext_id_svr_user_attribute "sAMAccountName" \
  --ext_id_svr_bind_type "search_bind" \
  --ext_id_svr_bind_dn "cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com" \
  --ext_id_svr_host "${AD_SERVER_PRIVATE_IP}" \
  --ext_id_svr_group_attribute "memberOf" \
  --ext_id_svr_security_protocol "ldaps" \
  --ext_id_svr_base_dn "CN=Users,DC=samdom,DC=example,DC=com" \
  --ext_id_svr_verify_peer false \
  --ext_id_svr_type "Active Directory" \
  --ext_id_svr_port 636 \
  --external-groups "${EXTERNAL_GROUPS}")

echo CLUSTER_ID=$CLUSTER_ID

hpecp k8scluster wait-for-status --id $CLUSTER_ID --status [ready] --timeout-secs 3600
echo "K8S cluster created successfully - ID: ${CLUSTER_ID}"

# echo 'Adding addon ["kubeflow","picasso-compute"] | timeout=1800s'
# hpecp k8scluster add-addons --id $CLUSTER_ID --addons '["kubeflow","picasso-compute"]'
# hpecp k8scluster wait-for-status --id $CLUSTER_ID --status [ready] --timeout-secs 1800
# echo "Addon successfully added"

echo "Creating tenant"
TENANT_ID=$(hpecp tenant create --name "k8s-tenant-1" --description "dev tenant" --k8s-cluster-id $CLUSTER_ID  --tenant-type k8s --features '{ ml_project: true }' --quota-cores 1000)
hpecp tenant wait-for-status --id $TENANT_ID --status [ready] --timeout-secs 1800
echo "K8S tenant created successfully - ID: ${TENANT_ID}"
echo TENANT_ID=$TENANT_ID

TENANT_NS=$(hpecp tenant get $TENANT_ID | grep "^namespace: " | cut -d " " -f 2)
echo TENANT_NS=$TENANT_NS

ADMIN_GROUP="CN=${AD_ADMIN_GROUP},CN=Users,DC=samdom,DC=example,DC=com"
ADMIN_ROLE=$(hpecp role list  --query "[?label.name == 'Admin'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id "$TENANT_ID" --group "$ADMIN_GROUP" --role-id "$ADMIN_ROLE"

MEMBER_GROUP="CN=${AD_MEMBER_GROUP},CN=Users,DC=samdom,DC=example,DC=com"
MEMBER_ROLE=$(hpecp role list  --query "[?label.name == 'Member'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id "$TENANT_ID" --group "$MEMBER_GROUP" --role-id "$MEMBER_ROLE"

echo "Configured tenant with AD groups Admins=${AD_ADMIN_GROUP}... and Members=${AD_MEMBER_GROUP}..."

ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

set -x
   
###
### MLFLOW Secret
###

echo "Creating MLFLOW secret"
cat <<EOF_YAML | kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS apply -f -
apiVersion: v1 
data: 
  MLFLOW_ARTIFACT_ROOT: czM6Ly9tbGZsb3c= #s3://mlflow 
  AWS_ACCESS_KEY_ID: YWRtaW4= #admin 
  AWS_SECRET_ACCESS_KEY: YWRtaW4xMjM= #admin123 
kind: Secret
metadata: 
  name: mlflow-sc 
  labels: 
    kubedirector.hpe.com/secretType: mlflow 
type: Opaque 
EOF_YAML

###
### MLFLOW Cluster
###

echo "Launching MLFLOW Cluster"
cat <<EOF_YAML | kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS apply -f -
apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata: 
  name: "$MLFLOW_CLUSTER_NAME"
  namespace: "$TENANT_NS"
  labels: 
    description: "mlflow"
spec: 
  app: "mlflow"
  namingScheme: "CrNameRole"
  appCatalog: "local"
  connections:
    secrets:
      - mlflow-sc
  roles: 
    - 
      id: "controller"
      members: 1
      resources: 
        requests: 
          cpu: "2"
          memory: "4Gi"
          nvidia.com/gpu: "0"
        limits: 
          cpu: "2"
          memory: "4Gi"
          nvidia.com/gpu: "0"
      #Note: "if the application is based on hadoop3 e.g. using StreamCapabilities interface, then change the below dtap label to 'hadoop3', otherwise for most applications use the default 'hadoop2'"
      podLabels: 
        hpecp.hpe.com/dtap: "hadoop2"
EOF_YAML

EOF1

echo "Setting up Notebook"
./bin/experimental/setup_notebook.sh $TENANT_ID

echo "Waiting for mlflow KD app to have state==configured"
./bin/experimental/minio_wait_for_mlflow_configured_state.sh $TENANT_ID mlflow

echo "Retrieving minio gateway host and port"
MINIO_HOST_AND_PORT="$(./bin/experimental/minio_get_gw_host_and_port.sh $TENANT_ID mlflow)"
echo MINIO_HOST_AND_PORT=$MINIO_HOST_AND_PORT

echo "Creating minio bucket"
./bin/experimental/minio_create_bucket.sh "$MINIO_HOST_AND_PORT"

