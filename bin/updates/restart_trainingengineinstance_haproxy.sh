#!/bin/bash 

  set -e
  set -o pipefail


if [[ -z $1 ]]; then
  echo Usage: $0 TENANT_ID
  exit 1
fi

set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

echo "Running script: $0 $@"

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

export TENANT_ID=$1
echo $TENANT_ID

export CLUSTER_ID=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [_links.k8scluster]" --output text)
echo CLUSTER_ID=$CLUSTER_ID

export TENANT_NS=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [namespace]" --output text)
echo TENANT_NS=$TENANT_NS

ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  set -e
  set -u 
  set -o pipefail

  POD=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    get pod -l kubedirector.hpe.com/kdcluster=trainingengineinstance,kubedirector.hpe.com/role=LoadBalancer -n $TENANT_NS -o 'jsonpath={.items..metadata.name}')

  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    exec -c app -n $TENANT_NS \$POD -- systemctl restart haproxy 

EOF1
