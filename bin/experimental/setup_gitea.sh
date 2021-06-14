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
---
EOF_YAML

if [[ "$ACTION" == "apply" ]]; then

  # sleep 60

  POD=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS get pods -l app=gitea --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
  echo POD=\$POD
  
  while [[ \$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) -n $TENANT_NS get pods \$POD -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done
  
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- curl -s -X POST -d 'db_type=SQLite3&db_host=localhost%3A3306&db_user=root&db_passwd=&db_name=gitea&ssl_mode=disable&db_schema=&charset=utf8&db_path=%2Fdata%2Fgitea%2Fgitea.db&app_name=Gitea%3A+Git+with+a+cup+of+tea&repo_root_path=%2Fdata%2Fgit%2Frepositories&lfs_root_path=%2Fdata%2Fgit%2Flfs&run_user=git&domain=localhost&ssh_port=22&http_port=3000&app_url=http%3A%2F%2Fip-10-1-0-223.eu-west-3.compute.internal%3A10038%2F&log_root_path=%2Fdata%2Fgitea%2Flog&smtp_host=&smtp_from=&smtp_user=&smtp_passwd=&enable_federated_avatar=on&no_reply_address=&password_algorithm=pbkdf2&admin_name=&admin_passwd=&admin_confirm_passwd=&admin_email=' http://localhost:3000

  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) exec -n $TENANT_NS \$POD -- curl -s -X GET http://localhost:3000

fi

EOF1