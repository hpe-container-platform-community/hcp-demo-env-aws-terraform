#!/bin/bash

exec > >(tee -i generated/log-$(basename $0).txt)
exec 2>&1

set -e
set -u
set -o pipefail

source ./scripts/variables.sh
source ./scripts/functions.sh

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

if [[ -z $1 ]]; then
  echo Usage: $0 TENANT_ID
  exit 1
fi

TENANT_ID=$1

export MLFLOW_CLUSTER_NAME=mlflow
echo MLFLOW_CLUSTER_NAME=$MLFLOW_CLUSTER_NAME

export TENANT_NS=$(hpecp tenant get $TENANT_ID | grep "^namespace: " | cut -d " " -f 2)
echo TENANT_NS=$TENANT_NS

export CLUSTER_ID=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [_links.k8scluster]" --output text)
echo CLUSTER_ID=$CLUSTER_ID

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
      storage: 
        size: "20Gi"
        storageClassName: "dfdemo"
        
      #Note: "if the application is based on hadoop3 e.g. using StreamCapabilities interface, then change the below dtap label to 'hadoop3', otherwise for most applications use the default 'hadoop2'"
      podLabels: 
        hpecp.hpe.com/dtap: "hadoop2"
EOF_YAML

  echo Waiting for MLFLOW cluster to have state==configured
  
  COUNTER=0
  while [ \$COUNTER -lt 30 ]; 
  do
    STATE=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
                get kubedirectorcluster -n $TENANT_NS $MLFLOW_CLUSTER_NAME -o 'jsonpath={.status.state}')
    echo STATE=\$STATE
    [[ \$STATE == "configured" ]] && break
    sleep 1m
    let COUNTER=COUNTER+1 
  done

EOF1
