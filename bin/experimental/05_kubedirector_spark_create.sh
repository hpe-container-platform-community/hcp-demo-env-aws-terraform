#!/bin/bash 

set -e
set -u

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh


# add private key to AD server to allow passwordless ssh to all other hosts
if [[  "$AD_SERVER_ENABLED" != "True" && "$AD_PUB_IP" ]]; then
   echo "AD Server is required. Aborting."
   exit 1
fi

ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@"${AD_PUB_IP}" <<-SSH_EOF
   sudo yum install -y python-pip3
   pip3 install --quiet --upgrade --user hpecp

   # use the project's HPECP CLI config file
   export HPECP_CONFIG_FILE="~/hpecp.conf"

   cat >~/hpecp.conf<<CAT_EOF
[default]
api_host = ${CTRL_PRV_IP}
api_port = 8080
use_ssl = ${INSTALL_WITH_SSL}
verify_ssl = False
warn_ssl = False
username = admin
password = admin123
CAT_EOF

   # Test CLI is able to connect
   echo "Platform ID: $(hpecp license platform-id)"

   TENANT_ID=\$(hpecp tenant list --query "[?tenant_type == 'k8s' && label.name == 'k8s-tenant-1'] | [0] | [_links.self.href]" --output text)

cat >>~/hpecp.conf<<CAT_EOF

[k8s-tenant-1]
tenant = \${TENANT_ID}
username = ad_admin1
password = pass123
CAT_EOF

   cat ~/hpecp.conf

   export PROFILE=k8s-tenant-1
   hpecp tenant k8skubeconfig > k8s-tenant-1-kubeconfig.conf

   command -v kubectl > /dev/null || {
      curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
      chmod +x ./kubectl
      sudo mv ./kubectl /usr/local/bin/kubectl
   }

   command -v kubectl-hpecp > /dev/null || {
      curl -L0 "https://bluedata-releases.s3.amazonaws.com/kubectl-epic/3.2/162/linux/kubectl-hpecp" > kubectl-hpecp
      chmod +x ./kubectl-hpecp
      sudo mv ./kubectl-hpecp /usr/local/bin/kubectl-hpecp
   }

   echo y | kubectl hpecp authenticate --hpecp-user ad_admin1 --hpecp-pass pass123 --hpecp ${CTRL_PRV_IP}
   kubectl --kubeconfig k8s-tenant-1-kubeconfig.conf get pods

cat >~/spark245.yaml<<CAT_EOF
---
apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata: 
  name: "spark245-instance"
  namespace: "hpecp-tenant-6-vzqcv"
spec: 
  app: "spark245"
  appCatalog: "local"
  #connections: 
    #secrets: 
      #- 
        #"some secrets"
    #configmaps: 
      #- 
        #"some configmaps"
    #clusters: 
      #- 
        #"some clusters"
  roles: 
    - 
      id: "spark-master"
      members: 1
      resources: 
        requests: 
          memory: "4Gi"
          cpu: "2"
        limits: 
          memory: "4Gi"
          cpu: "2"
      storage: 
        size: "50Gi"
    - 
      id: "livy-server"
      members: 1
      resources: 
        requests: 
          memory: "4Gi"
          cpu: "2"
        limits: 
          memory: "4Gi"
          cpu: "2"
      storage: 
        size: "50Gi"
    - 
      id: "spark-worker"
      members: 1
      resources: 
        requests: 
          memory: "4Gi"
          cpu: "2"
        limits: 
          memory: "4Gi"
          cpu: "2"
      storage: 
        size: "50Gi"
    - 
      id: "notebook-server"
      members: 0
      resources: 
        requests: 
          memory: "4Gi"
          cpu: "2"
        limits: 
          memory: "4Gi"
          cpu: "2"
      storage: 
        size: "50Gi"
CAT_EOF

kubectl --kubeconfig k8s-tenant-1-kubeconfig.conf apply -f ~/spark245.yaml
SSH_EOF