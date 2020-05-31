This document is a work-in-progress.
----

- Create a K8s 1.17.0 Cluster with 1 master and 1 worker node

- Provision F5 AWS image inside VPC managed by Terraform

```
ln -s docs/README-F5-BIGIP/bluedata_infra_main_bigip.tf .
# EDIT the above file if you are not deploying in Oregon

# Example: https://www.youtube.com/watch?v=XUjDMY9i29I&feature=youtu.be

ssh -o StrictHostKeyChecking=no -i ./generated/controller.prv_key admin@$(terraform output bigip_public_ip)
modify auth user admin password in5ecurP55wrd 
save sys config 

# Create a BIPIP partition - https://techdocs.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/tmos-implementations-12-1-0/29.html
open "https://$(terraform output bigip_public_ip):8443"
```

- Create service account

```
kubectl create serviceaccount bigip-ctlr -n kube-system
```

- Create namespace
```
kubectl create namespace bigip-namespace
```


- From: https://clouddocs.f5.com/containers/v2/kubernetes/kctlr-secrets.html#secret-bigip-login
```
kubectl create secret generic bigip-login \
  --namespace kube-system \
  --from-literal=username=admin \
  --from-literal=password=<your_password>
```

- From: https://clouddocs.f5.com/containers/v2/kubernetes/kctlr-app-install.html#set-up-rbac-authentication
```
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
BIGIP_IP=10.1.0.25 # 52.25.28.177 # change this
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
