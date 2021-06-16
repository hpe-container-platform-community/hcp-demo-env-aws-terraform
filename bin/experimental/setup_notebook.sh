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
echo $TENANT_ID

export NB_CLUSTER_NAME=nb
echo NB_CLUSTER_NAME=$NB_CLUSTER_NAME

export MLFLOW_CLUSTER_NAME=mlflow
echo MLFLOW_CLUSTER_NAME=$MLFLOW_CLUSTER_NAME

export TRAINING_CLUSTER_NAME=trainingengineinstance
echo TRAINING_CLUSTER_NAME=$TRAINING_CLUSTER_NAME

export AD_USER_NAME=ad_user1
echo AD_USER_NAME=$AD_USER_NAME

export AD_USER_PASS=pass123
echo AD_USER_PASS=$AD_USER_PASS


export CLUSTER_ID=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [_links.k8scluster]" --output text)
echo CLUSTER_ID=$CLUSTER_ID

export TENANT_NS=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [namespace]" --output text)
echo TENANT_NS=$TENANT_NS

# login as the ad_user1 user so that the user account gets added and an ID created (e.g. /api/v1/user/22)
ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  set -e
  set -u 
  set -o pipefail

cat > ~/.hpecp_tenant.conf <<CAT_EOF
[default]
api_host = ${CTRL_PRV_IP}
api_port = 8080
use_ssl = ${INSTALL_WITH_SSL}
verify_ssl = False
warn_ssl = False

[tenant]
tenant = $TENANT_ID
username = $AD_USER_NAME
password = $AD_USER_PASS
CAT_EOF

cat ~/.hpecp_tenant.conf
	
PROFILE=tenant HPECP_CONFIG_FILE=~/.hpecp_tenant.conf hpecp tenant k8skubeconfig

EOF1

export AD_USER_ID=$(hpecp user list --query "[?label.name=='$AD_USER_NAME'] | [0] | [_links.self.href]" --output text | cut -d '/' -f 5 | sed '/^$/d')
export AD_USER_SECRET_HASH=$(python3 -c "import hashlib; print(hashlib.md5('$AD_USER_ID-$AD_USER_NAME'.encode('utf-8')).hexdigest())")
export AD_USER_KC_SECRET="hpecp-kc-secret-$AD_USER_SECRET_HASH"

echo AD_USER_ID=$AD_USER_ID
echo AD_USER_KC_SECRET=$AD_USER_KC_SECRET


ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  set -e
  set -u 
  set -o pipefail

  set +e
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS get secret $AD_USER_KC_SECRET
  if [[ \$? == 0 ]]; then
    echo "Secret $AD_USER_KC_SECRET exists - removing"
    kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS delete secret $AD_USER_KC_SECRET
  fi
  set -e

cat > ~/.hpecp_tenant.conf <<CAT_EOF
[default]
api_host = ${CTRL_PRV_IP}
api_port = 8080
use_ssl = ${INSTALL_WITH_SSL}
verify_ssl = False
warn_ssl = False

[tenant]
tenant = $TENANT_ID
username = $AD_USER_NAME
password = $AD_USER_PASS
CAT_EOF

cat ~/.hpecp_tenant.conf
	
export AD_USER_KUBECONFIG="\$(PROFILE=tenant HPECP_CONFIG_FILE=~/.hpecp_tenant.conf hpecp tenant k8skubeconfig | sed -z 's/\n/\\\n/g')"
# printf "AD_USER_KUBECONFIG=\$AD_USER_KUBECONFIG"

echo

export DATA_BASE64=\$(base64 -w 0 <<END
{
  "stringData": {
    "config": "\$AD_USER_KUBECONFIG"
  },
  "kind": "Secret",
  "apiVersion": "v1",
  "metadata": {
    "labels": {
      "kubedirector.hpe.com/username": "$AD_USER_NAME",
      "kubedirector.hpe.com/userid": "$AD_USER_ID",
      "kubedirector.hpe.com/secretType": "kubeconfig"
    },
    "namespace": "$TENANT_NS",
    "name": "$AD_USER_KC_SECRET"
  }
}
END
)

echo DATA_BASE64=\$DATA_BASE64

export LOG_LEVEL=DEBUG

PROFILE=tenant HPECP_CONFIG_FILE=~/.hpecp_tenant.conf hpecp httpclient post $CLUSTER_ID/kubectl <(echo -n '{"data":"'\$DATA_BASE64'","op":"create"}')


###
### Training Cluster
###

echo "Launching Training Cluster"
cat <<EOF_YAML | kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS apply -f -

apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata: 
  name: "$TRAINING_CLUSTER_NAME"
  namespace: "$TENANT_NS"
  labels: 
    description: ""
spec: 
  app: "training-engine"
  namingScheme: "CrNameRole"
  appCatalog: "local"
  connections: 
    secrets: 
      - $AD_USER_KC_SECRET
      - hpecp-ext-auth-secret
  roles: 
    - 
      id: "LoadBalancer"
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
    - 
      id: "RESTServer"
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

echo Waiting for Training to have state==configured
  
  COUNTER=0
  while [ \$COUNTER -lt 30 ]; 
  do
    STATE=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
                get kubedirectorcluster -n $TENANT_NS $TRAINING_CLUSTER_NAME -o 'jsonpath={.status.state}')
    echo STATE=\$STATE
    [[ \$STATE == "configured" ]] && break
    sleep 1m
    let COUNTER=COUNTER+1 
  done

###
### Jupyter Notebook
###

export AD_USER_ID=$AD_USER_ID

echo "Launching Jupyter Notebook as '$AD_USER_NAME' user ($AD_USER_ID)"
cat <<EOF_YAML | kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS apply -f -
apiVersion: "kubedirector.hpe.com/v1beta1"
kind: "KubeDirectorCluster"
metadata: 
  name: "$NB_CLUSTER_NAME"
  namespace: "$TENANT_NS"
  labels: 
    "kubedirector.hpe.com/createdBy": "$AD_USER_ID"
spec: 
  app: "jupyter-notebook"
  appCatalog: "local"
  connections:
    clusters:
      - $MLFLOW_CLUSTER_NAME
      - $TRAINING_CLUSTER_NAME
    secrets: 
      - hpecp-sc-secret-gitea-ad-user1-nb
      - hpecp-ext-auth-secret
      - mlflow-sc
      - $AD_USER_KC_SECRET
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

./bin/ssh_rdp_linux_server.sh rm -rf static/
./bin/ssh_rdp_linux_server.sh mkdir static/

for FILE in $(ls -1 static/*)
do
  cat $FILE | ./bin/ssh_rdp_linux_server.sh "cat > $FILE"
done


ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  set -e
  set -u 
  set -o pipefail

  echo Waiting for Notebook to have state==configured
  
  COUNTER=0
  while [ \$COUNTER -lt 30 ]; 
  do
    STATE=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
                get kubedirectorcluster -n $TENANT_NS $NB_CLUSTER_NAME -o 'jsonpath={.status.state}')
    echo STATE=\$STATE
    [[ \$STATE == "configured" ]] && break
    sleep 1m
    let COUNTER=COUNTER+1 
  done

  # Retrieve the notebook pod

  POD=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    get pod -l kubedirector.hpe.com/kdcluster=$NB_CLUSTER_NAME -n $TENANT_NS -o 'jsonpath={.items..metadata.name}')
    
  echo TENANT_NS=$TENANT_NS
  echo POD=\$POD
  
  TENANT_USER=ad_user1
  
  echo "Login to notebook to create home folders for \${TENANT_USER}"
    
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    exec -c app -n $TENANT_NS \$POD -- sudo su - \${TENANT_USER}
  
  echo "Copying example files to notebook pods"
  
  # for FILE in \$(ls -1 ./static/*)
  # do
  #   BASEFILE=\$(basename \$FILE)
  #   kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
  #     cp --container app \$FILE $TENANT_NS/\$POD:/home/\${TENANT_USER}/\${BASEFILE}
      
  #   kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
  #     exec -c app -n $TENANT_NS \$POD -- chown ad_user1:domain\\ users /home/\${TENANT_USER}/\${BASEFILE}
   
  #   if [[ "\${BASEFILE##*.}" == ".sh" ]]; then
  #     kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
  #       exec -c app -n $TENANT_NS \$POD -- chmod +x /home/\${TENANT_USER}/\${BASEFILE}
  #   fi
  # done
   
  echo "Adding pytest and nbval python libraries for testing"

  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    exec -c app -n $TENANT_NS \$POD -- sudo -E -u \${TENANT_USER} /opt/miniconda/bin/pip3 install --user --quiet --no-warn-script-location pytest nbval

  echo "Setup HPECP CLI as admin user"
  
  cat > ~/.hpecp_tenant.conf_tmp <<CAT_EOF
[default]
api_host = ${CTRL_PRV_IP}
api_port = 8080
use_ssl = ${INSTALL_WITH_SSL}
verify_ssl = False
warn_ssl = False
username = admin
password = admin123
CAT_EOF
  
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    cp --container app ~/.hpecp_tenant.conf_tmp $TENANT_NS/\$POD:/home/\${TENANT_USER}/.hpecp.conf

  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    exec -c app -n $TENANT_NS \$POD -- chown ad_user1:root /home/\${TENANT_USER}/.hpecp.conf

  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    exec -c app -n $TENANT_NS \$POD -- chmod 600 /home/\${TENANT_USER}/.hpecp.conf
  
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    exec -c app -n $TENANT_NS \$POD -- sudo -E -u \${TENANT_USER} /opt/miniconda/bin/pip3 install --user --quiet --no-warn-script-location hpecp
    
EOF1
