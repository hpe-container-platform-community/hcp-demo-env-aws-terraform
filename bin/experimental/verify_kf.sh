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
source ./scripts/functions.sh

print_header "Running script: $0 $@"

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

export TENANT_ID=$1
#echo $TENANT_ID

export CLUSTER_ID=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [_links.k8scluster]" --output text)
#echo CLUSTER_ID=$CLUSTER_ID

export CLUSTER_NUMBER=$(basename $CLUSTER_ID)
#echo CLUSTER_NUMBER=$CLUSTER_NUMBER

ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  hpecp k8scluster --id $CLUSTER_ID admin-kube-config \
    > kubeconfig_admin_$CLUSTER_NUMBER.conf
    
  #cat kubeconfig_admin_$CLUSTER_NUMBER.conf
  
  pip3 install --quiet kubernetes
EOF1

# login as the ad_user1 user so that the user account gets added and an ID created (e.g. /api/v1/user/22)
ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} python3 - <<-EOF1

import sys
from kubernetes import client, config

pods_templates = [
    "authservice-",
    "cluster-local-",
    "istio-citadel-",
    "istio-galley-",
    "istio-ingressgateway-",
    "istio-nodeagent-",
    "istio-pilot-",
    "istio-policy-",
    "istio-security-post-install-",
    "istio-sidecar-injector-",
    "istio-telemetry-",
    "kfserving-ingressgateway-",
    "prometheus-",
    "admission-webhook-deployment-",
    "application-controller-stateful-set-",
    "argo-ui-",
    "centraldashboard-",
    "jupyter-web-app-deployment-",
    "katib-controller-",
    "katib-db-manager-",
    "katib-mysql-",
    "katib-ui-",
    "kfserving-controller-manager-",
    "minio-",
    "ml-pipeline-ml-pipeline-visualizationserver-",
    "ml-pipeline-persistenceagent-",
    "ml-pipeline-scheduledworkflow-",
    "ml-pipeline-ui-",
    "ml-pipeline-viewer-controller-deployment-",
    "ml-pipeline-",
    "mysql-",
    "notebook-controller-deployment-",
    "profiles-deployment-",
    "pytorch-operator-",
    "seldon-controller-manager-",
    "spartakus-volunteer-",
    "tf-job-operator-",
    "workflow-controller-",
    "dex-"
]

config.load_kube_config('kubeconfig_admin_$CLUSTER_NUMBER.conf')
v1 = client.CoreV1Api()

pod_list = v1.list_namespaced_pod("istio-system")
pods = pod_list.items
pod_list = v1.list_namespaced_pod("kubeflow")
pods.extend(pod_list.items)
pod_list = v1.list_namespaced_pod("auth")
pods.extend(pod_list.items)
for pod in pods:
    name = pod.metadata.name
    status = pod.status.phase
    print(status, name)
    if status == 'Succeeded' or (status == 'Running' and pod.status.container_statuses[0].ready):
        for template in pods_templates:
            if name.startswith(template):
                pods_templates.remove(template)
                break

print()
print(pods_templates)

sys.exit(len(pods_templates))

EOF1

