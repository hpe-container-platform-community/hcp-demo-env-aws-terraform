#!/bin/bash 

set -e
set -o pipefail

if [[ -z "$1" ]]; then
  echo "Usage: $0 TENANT_ID"
  echo "Where:"
  echo "       TENANT_ID = tenant where gitea is deployed"
  exit 1
fi

set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh
source ./scripts/functions.sh

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

export TENANT_ID=$1
export CLUSTER_ID=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [_links.k8scluster]" --output text)
export TENANT_NS=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [namespace]" --output text)

ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  set -e
  set -u 
  set -o pipefail

  EXTERNAL_URL=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS get service gitea-service \
    -o 'jsonpath={..annotations.hpecp-internal-gateway/3000}')
  echo "http://\$EXTERNAL_URL"
  
  hpecp httpclient post /api/v2/gitops_repo <(echo "
{
  \"repository_url\": \"http://\$EXTERNAL_URL/administrator/gatekeeper-library.git\",
  \"repository_username\": \"administrator\",
  \"repository_password\": \"admin123\"
}
") || true # ignore conflicts


REPO_ID=\$(
  hpecp httpclient get /api/v2/gitops_repo \
      | python3 -c "import json,sys;obj=json.load(sys.stdin);[ print(t['_links']['self']['href']) for t in obj['_embedded']['gitops_repos'] if t['repository_url'] == 'http://\$EXTERNAL_URL/administrator/gatekeeper-library']"
)
echo REPO_ID=\$REPO_ID

#####

 LOG_LEVEL=DEBUG hpecp httpclient post /api/v2/gitops_app <(echo "
{
     \"gitops_repo\": \"\$REPO_ID\",
     \"app_source\": {
           \"path\": \"library/pod-security-policy/read-only-root-filesystem\",
           \"target_revision\": \"HEAD\"
        },
     \"label\": {
          \"name\": \"read-only-root-filesystem\",
          \"description\": \"\"
      }
}
")


EOF1


