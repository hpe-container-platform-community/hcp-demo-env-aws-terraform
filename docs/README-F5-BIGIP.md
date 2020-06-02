THIS DOCUMENT IS A WORK-IN-PROGRESS
----

```bash
# Set etc/bluedata_infra.tfvars with URL for HPECP 5.1 (1289+ engineering build)

ln -s docs/README-F5-BIGIP/bluedata_infra_main_bigip.tf .
# EDIT the AMI id in the above file if you are not deploying in Oregon

./bin/create_new_environment_from_scratch.sh

# wait for BIGIP to initialise
sleep 600

# Update BIGIP password
ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key admin@$(terraform output bigip_public_ip) <<EOF
modify auth user admin password in5ecurP55wrd
create /auth partition demopartition
# display the management interface ip address
list /sys management-ip
show /sys version
save sys config
EOF

# BIGIP management interface
open https://$(terraform output bigip_private_ip_1)
```

Configure HPE CP

```
./bin/experimental/01_configure_global_active_directory.sh
./bin/experimental/02_gateway_add.sh
./bin/experimental/03_k8sworkers_add.sh

hpecp k8sworker list
# +-----------+--------+------------------------------------------+------------+---------------------------+
# | worker_id | status |                 hostname                 |   ipaddr   |           href            |
# +-----------+--------+------------------------------------------+------------+---------------------------+
# |    3      | ready  | ip-10-1-0-178.us-west-2.compute.internal | 10.1.0.178 | /api/v2/worker/k8shost/3  |
# |    4      | ready  | ip-10-1-0-93.us-west-2.compute.internal  | 10.1.0.93  | /api/v2/worker/k8shost/4  |
# +-----------+--------+------------------------------------------+------------+---------------------------+

# get the HPE CP supported k8s 1.15.x version number - BIGIP docs state this was the latest tested version
KVERS=$(hpecp k8scluster k8s-supported-versions --output text --major-filter 1 --minor-filter 15)
echo $KVERS

# setup values from `hpecp k8sworker list'
MASTER_ID="/api/v2/worker/k8shost/3"
WORKER_ID="/api/v2/worker/k8shost/4"
MASTER_IP=$(hpecp k8sworker get ${MASTER_ID} | grep '^ipaddr' | cut -d " " -f 2)
CLUS_NAME="kubeflow_cluster"

# create a K8s Cluster
CLUS_ID=$(hpecp k8scluster create ${CLUS_NAME} ${MASTER_ID}:master,${WORKER_ID}:worker --k8s-version $KVERS)
echo $CLUS_ID

# wait until ready
hpecp k8scluster wait-for-status $CLUS_ID --status "['ready']" --timeout-secs 1200

# check connectivity to server - you may need to start vpn with:
# ./generated/vpn_server_setup.sh
# sudo ./generated/vpn_mac_connect.sh
ping -c 5 $MASTER_IP
```
If the above ping fails, connect to the VPN:

```
./generated/vpn_server_setup.sh
sudo ./generated/vpn_mac_connect.sh
```

Setup the k8s cluster

```
export KUBECONFIG=./generated/clus_kfg
hpecp k8scluster admin-kube-config ${CLUS_ID} > ${KUBECONFIG}

# Create service account
kubectl create serviceaccount bigip-ctlr -n kube-system

# Create namespace
kubectl create namespace bigip-namespace

# From: https://clouddocs.f5.com/containers/v2/kubernetes/kctlr-secrets.html#secret-bigip-login
kubectl create secret generic bigip-login \
  --namespace kube-system \
  --from-literal=username=admin \
  --from-literal=password=in5ecurP55wrd

# From: https://clouddocs.f5.com/containers/v2/kubernetes/kctlr-app-install.html#set-up-rbac-authentication

cat > rbac.yaml <<EOF
# for use in k8s clusters only
# for OpenShift, use the OpenShift-specific examples
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: bigip-ctlr-clusterrole
rules:
- apiGroups: ["", "extensions"]
  resources: ["nodes", "services", "endpoints", "namespaces", "ingresses", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["", "extensions"]
  resources: ["configmaps", "events", "ingresses/status"]
  verbs: ["get", "list", "watch", "update", "create", "patch"]
- apiGroups: ["", "extensions"]
  resources: ["secrets"]
  resourceNames: ["bigip-login"]
  verbs: ["get", "list", "watch"]

---

kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: bigip-ctlr-clusterrole-binding
  namespace: bigip-namespace
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: bigip-ctlr-clusterrole
subjects:
- apiGroup: ""
  kind: ServiceAccount
  name: bigip-ctlr
  namespace: bigip-namespace
EOF
kubectl apply -f rbac.yaml 
```

- From: https://clouddocs.f5.com/containers/v2/kubernetes/kctlr-app-install.html#basic-deployment

```
BIGIP_IP=$(terraform output bigip_private_ip_1)
BIGIP_PARTITION=demopartition


cat > deployment.yaml <<EOF
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: k8s-bigip-ctlr-deployment
  namespace: kube-system
spec:
  # DO NOT INCREASE REPLICA COUNT
  replicas: 1
  template:
    metadata:
      name: k8s-bigip-ctlr
      labels:
        app: k8s-bigip-ctlr
    spec:
      # Name of the Service Account bound to a Cluster Role with the required
      # permissions
      serviceAccountName: bigip-ctlr
      containers:
        - name: k8s-bigip-ctlr
          image: "f5networks/k8s-bigip-ctlr"
          env:
            - name: BIGIP_USERNAME
              valueFrom:
                secretKeyRef:
                  # Replace with the name of the Secret containing your login
                  # credentials
                  name: bigip-login
                  key: username
            - name: BIGIP_PASSWORD
              valueFrom:
                secretKeyRef:
                  # Replace with the name of the Secret containing your login
                  # credentials
                  name: bigip-login
                  key: password
          command: ["/app/bin/k8s-bigip-ctlr"]
          args: [
            # See the k8s-bigip-ctlr documentation for information about
            # all config options
            # https://clouddocs.f5.com/products/connectors/k8s-bigip-ctlr/latest
            "--bigip-username=\$(BIGIP_USERNAME)",
            "--bigip-password=\$(BIGIP_PASSWORD)",
            "--bigip-url=${BIGIP_IP}",
            "--bigip-partition=${BIGIP_PARTITION}",
            "--insecure=true",
            "--pool-member-type=nodeport",
            "--agent=as3",
            ]
      imagePullSecrets:
        # Secret that gives access to a private docker registry
        - name: f5-docker-images
        # Secret containing the BIG-IP system login credentials
        - name: bigip-login
EOF
kubectl apply -f deployment.yaml
```
Test application

```
kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment web --type=NodePort --port=8080
```
