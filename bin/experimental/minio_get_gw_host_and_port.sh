#!/bin/bash 

set -e

if [[ -z $1 || -z $2 ]]; then
  echo Usage: $0 TENANT_ID MLFLOW_KD_CLUSTERNAME
  exit 1
fi

set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

export TENANT_ID=$1
export MLFLOW_CLUSTER_NAME=$2


ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  export CLUSTER_ID=\$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [_links.k8scluster]" --output text)
  export TENANT_NS=\$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [namespace]" --output text)

  HOST_AND_PORT=\$(kubectl --kubeconfig <(hpecp k8scluster --id \$CLUSTER_ID admin-kube-config) \
    get service -l kubedirector.hpe.com/kdcluster=$MLFLOW_CLUSTER_NAME -n \$TENANT_NS \
    -o jsonpath={.items[0].metadata.annotations.'hpecp-internal-gateway/9000'})
    
  echo \$HOST_AND_PORT

EOF1