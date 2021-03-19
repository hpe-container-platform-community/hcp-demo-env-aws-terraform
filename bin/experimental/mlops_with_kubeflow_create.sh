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

K8S_WORKER_1=$1
K8S_WORKER_2=$2


if [[ $K8S_WORKER_1 =~ ^\/api\/v2\/worker\/k8shost\/[0-9]$ ]] && [[ $K8S_WORKER_2 =~ ^\/api\/v2\/worker\/k8shost\/[0-9]$ ]]; 
then
   echo 
else
   echo "Usage: $0 /api/v2/worker/k8shost/[0-9] /api/v2/worker/k8shost/[0-9]"
   exit 1
fi


set -u

K8S_VERSION=$(hpecp k8scluster k8s-supported-versions --major-filter 1 --minor-filter 20 --output text)

AD_SERVER_PRIVATE_IP=$(terraform output ad_server_private_ip)

EXTERNAL_IDENTITY_SERVER="{\"bind_pwd\":\"5ambaPwd@\",\"user_attribute\":\"CN\",\"bind_type\":\"search_bind\",\"bind_dn\":\"cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com\",\"host\":\"${AD_SERVER_PRIVATE_IP}\",\"group_attribute\":\"member\",\"security_protocol\":\"ldaps\",\"base_dn\":\"CN=Users,DC=samdom,DC=example,DC=com\",\"verify_peer\":false,\"type\":\"Active Directory\",\"port\":636}"

echo "Creating k8s cluster with version ${K8S_VERSION} and addons=[kubeflow] | timeout=1800s"
CLUSTER_ID=$(hpecp k8scluster create --name c1 --k8s-version $K8S_VERSION --k8shosts-config "$K8S_WORKER_1:master,$K8S_WORKER_2:worker" --addons ["kubeflow"] --external-identity-server "${EXTERNAL_IDENTITY_SERVER}" --external-groups '["CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com","CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com"]')

echo "$CLUSTER_ID"

hpecp k8scluster wait-for-status --id $CLUSTER_ID --status [ready] --timeout-secs 3600
echo "K8S cluster created successfully - ID: ${CLUSTER_ID}"

echo "Adding addon [kubeflow] | timeout=1800s"
hpecp k8scluster add-addons --id $CLUSTER_ID --addons [kubeflow]
hpecp k8scluster wait-for-status --id $CLUSTER_ID --status [ready] --timeout-secs 1800
echo "Addon successfully added"

echo "Creating tenant"
TENANT_ID=$(hpecp tenant create --name "k8s-tenant-1" --description "dev tenant" --k8s-cluster-id $CLUSTER_ID  --tenant-type k8s --features '{ ml_project: true }' --quota-cores 1000)
hpecp tenant wait-for-status --id $TENANT_ID --status [ready] --timeout-secs 1800
echo "K8S tenant created successfully - ID: ${TENANT_ID}"

ADMIN_GROUP="CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com"
ADMIN_ROLE=$(hpecp role list  --query "[?label.name == 'Admin'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id "$TENANT_ID" --group "$ADMIN_GROUP" --role-id "$ADMIN_ROLE"

MEMBER_GROUP="CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com"
MEMBER_ROLE=$(hpecp role list  --query "[?label.name == 'Member'][_links.self.href] | [0][0]" --output json | tr -d '"')
hpecp tenant add-external-user-group --tenant-id "$TENANT_ID" --group "$MEMBER_GROUP" --role-id "$MEMBER_ROLE"

echo "Configured tenant with AD groups Admins=DemoTenantAdmins... and Members=DemoTenantUsers..."

echo "Launching Jupyter Notebook as 'admin' user"
ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

   ADMIN_ID=\$(hpecp user list --query "[?label.name=='admin'] | [0] | [_links.self.href]" --output text | cut -d '/' -f 5)
   TENANT_NS=\$(hpecp tenant get /api/v1/tenant/4 | grep "^namespace: " | cut -d " " -f 2)
   KC_SECRET=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n \$TENANT_NS get secrets | grep hpecp-kc-secret | cut -d " " -f 1)

   echo TENANT_NS=\$TENANT_NS
   echo KC_SECRET=\$KC_SECRET

cat <<EOF_YAML | kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n \$TENANT_NS apply -f -
apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata: 
  name: "nb"
  namespace: "\$TENANT_NS"
  labels: 
    "kubedirector.hpe.com/createdBy": "\$ADMIN_ID"
spec: 
  app: "jupyter-notebook"
  appCatalog: "local"
  connections: 
    secrets: 
      - hpecp-ext-auth-secret
      - \$KC_SECRET
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

