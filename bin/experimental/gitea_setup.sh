#!/bin/bash 

set -e
set -o pipefail


if [[ "$2" != "apply" && "$2" != "delete" ]]; then
  echo "Usage: $0 TENANT_ID ACTION"
  echo "Where:"
  echo "      ACTION = apply|delete"
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
echo TENANT_ID=$TENANT_ID

export ACTION=$2
echo ACTION=$ACTION

export CLUSTER_ID=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [_links.k8scluster]" --output text)
echo CLUSTER_ID=$CLUSTER_ID

export TENANT_NS=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [namespace]" --output text)
echo TENANT_NS=$TENANT_NS


ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  set -e
  set -u 
  set -o pipefail


cat <<EOF_YAML | kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS $ACTION -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitea
  labels:
    app: gitea
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitea
  template:
    metadata:
      labels:
        app: gitea
    spec:
      containers:
      - name: gitea
        image: gitea/gitea:1.14.2
        ports:
        - containerPort: 3000
          name: gitea
        - containerPort: 22
          name: git-ssh
        volumeMounts:
        - mountPath: /data
          name: git-data
        resources:
            limits:
                cpu:      2
                memory:   4Gi
      volumes:
      - name: git-data
        persistentVolumeClaim:
          claimName: gitea-pvc

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gitea-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
      
---
kind: Service
apiVersion: v1
metadata:
  name: gitea-service
  labels:
    hpecp.hpe.com/hpecp-internal-gateway: "true"
spec:
  selector:
    app: gitea
  ports:
  - name: http
    port: 3000
  - name: ssh
    port: 22
  type: NodePort

EOF_YAML

if [[ "$ACTION" == "apply" ]]; then

  while [[ \$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    get pods -l app=gitea -n $TENANT_NS -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done

  POD=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS get pods -l app=gitea --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
  echo POD=\$POD
  
  # while [[ \$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS \
  #   get pods \$POD -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done
  
  EXTERNAL_URL=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS get service gitea-service \
    -o 'jsonpath={..annotations.hpecp-internal-gateway/3000}')
  echo EXTERNAL_URL=\$EXTERNAL_URL
    
  EXTERNAL_URL_ESC=\$(echo "http://\$EXTERNAL_URL" | perl -MURI::Escape -wlne 'print uri_escape \$_')
  echo EXTERNAL_URL_ESC=\$EXTERNAL_URL_ESC
  
  EXTERNAL_HOSTNAME=\$(echo \$EXTERNAL_URL | cut -d ':' -f 1)
  echo EXTERNAL_HOSTNAME=\$EXTERNAL_HOSTNAME
  
  URL_DATA="db_type=SQLite3&db_host=localhost%3A3306&db_user=root&db_passwd=&db_name=gitea&ssl_mode=disable&db_schema=&charset=utf8&db_path=%2Fdata%2Fgitea%2Fgitea.db&app_name=Gitea%3A+Git+with+a+cup+of+tea&repo_root_path=%2Fdata%2Fgit%2Frepositories&lfs_root_path=%2Fdata%2Fgit%2Flfs&run_user=git&domain=\$EXTERNAL_HOSTNAME&ssh_port=22&http_port=3000&app_url=\$EXTERNAL_URL_ESC&log_root_path=%2Fdata%2Fgitea%2Flog&smtp_host=&smtp_from=&smtp_user=&smtp_passwd=&enable_federated_avatar=on&no_reply_address=&password_algorithm=pbkdf2&admin_name=&admin_passwd=&admin_confirm_passwd=&admin_email="
  echo URL_DATA=\$URL_DATA
  
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
    curl -s -d \$URL_DATA http://localhost:3000

  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
    su git -c 'gitea admin user create --username "administrator" --password "admin123" --email "admin@samdom.example.com" --admin --must-change-password=false' || true

  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
    su git -c 'gitea admin user create --username "ad_admin1" --password "pass123" --email "ad_admin1@samdom.example.com" --must-change-password=false' || true

  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
    su git -c 'gitea admin user create --username "ad_user1" --password "pass123" --email "ad_user1@samdom.example.com" --must-change-password=false' || true

  # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
  #   su git -c 'rm -rf /tmp/gatekeeper-library'
    
  # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
  #   su git -c 'gitea dump-repo --git_service github --clone_addr https://github.com/riteshja/gatekeeper-library --units issues,labels --repo_dir /tmp/gatekeeper-library'

  # # WORKAROUND FOR: [F] Failed to restore repository: open /tmp/gatekeeper-library/topic.yml: no such file or directory
  # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
  #   su git -c 'touch /tmp/gatekeeper-library/topic.yml'

  # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
  #   su git -c 'gitea restore-repo --repo_dir /tmp/gatekeeper-library --owner_name administrator --units issues,labels --repo_name gatekeeper-library' || true

###### ad_user1 repo

  # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
  #   su git -c 'rm -rf /tmp/jupyter-demo'

  # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
  #   su git -c 'gitea dump-repo --git_service github --clone_addr https://github.com/snowch/jupyter-demo --units issues,labels --repo_dir /tmp/jupyter-demo'

  # # WORKAROUND FOR: [F] Failed to restore repository: open /tmp/gatekeeper-library/topic.yml: no such file or directory
  # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
  #   su git -c 'touch /tmp/jupyter-demo/topic.yml'

  # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- \
  #   su git -c 'gitea restore-repo --repo_dir /tmp/jupyter-demo --owner_name ad_user1 --units issues,labels --repo_name jupyter-demo' || true


cat <<EOF_YAML | kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS $ACTION -f -
---
apiVersion: v1
stringData:
  authType: password #either of token or password. If token is selected, fill "token" field with token, otherwise "password" with password
  #token: my-github-token # fill this if authType is chosen as "token"
  password: \$(echo -n pass123 | base64) # fill this if authType is chosen as "password" - base64 encoded
  branch: master  
  email: ad_user1@samdom.example.com
  repoURL: http://\$EXTERNAL_URL/ad_user1/jupyter-demo.git  
  type: github   #either of "bitbucket" or "github"
  username: ad_user1 
  #proxyHostname: web-proxy.hpe.net #optional 
  #proxyPort: "8080" #optional 
  #proxyProtocol: http #http or https (optional)
kind: Secret
metadata:
  name: hpecp-sc-secret-gitea-ad-user1-nb
  labels:
    kubedirector.hpe.com/secretType: source-control
type: Opaque
EOF_YAML

fi

EOF1