THIS DOCUMENT IS A WORK IN PROGRESS
-----

### Kubeflow Install steps

- This script assumes you are creating a new terraform managed environment with 2 worker hosts:

```bash
set -e # abort on encountering an error
set -u # abort on encountering an undefined variable

# Set etc/bluedata_infra.tfvars with URL for HPECP 5.1 (1289+ engineering build)
./bin/create_new_environment_from_scratch.sh

./bin/experimental/01_configure_global_active_directory.sh
./bin/experimental/02_gateway_add.sh
./bin/experimental/03_k8sworkers_add.sh

hpecp k8sworker list
# +-----------+--------+------------------------------------------+------------+---------------------------+
# | worker_id | status |                 hostname                 |   ipaddr   |           href            |
# +-----------+--------+------------------------------------------+------------+---------------------------+
# |    16     | ready  | ip-10-1-0-178.us-west-2.compute.internal | 10.1.0.178 | /api/v2/worker/k8shost/16 |
# |    17     | ready  | ip-10-1-0-93.us-west-2.compute.internal  | 10.1.0.93  | /api/v2/worker/k8shost/17 |
# +-----------+--------+------------------------------------------+------------+---------------------------+

# get the HPE CP supported k8s 1.18.x version number
KVERS=$(hpecp k8scluster k8s-supported-versions --output text --major-filter 1 --minor-filter 18)
echo $KVERS

# replace IDs defined below with the ones from `hpecp k8sworker list'
MASTER_ID="/api/v2/worker/k8shost/16"
WORKER_ID="/api/v2/worker/k8shost/17"
MASTER_IP="10.1.0.178"

# create a K8s Cluster
CLUS_ID=$(hpecp k8scluster create clus1 ${MASTER_ID}:master,${WORKER_ID}:worker --k8s-version $KVERS)
echo $CLUS_ID

# wait until ready
hpecp k8scluster wait-for-status $CLUS_ID --status "['ready']" --timeout-secs 1200

# check connectivity to server - you may need to start vpn with:
# ./generated/vpn_server_setup.sh
# sudo ./generated/vpn_mac_connect.sh
ping -c 5 $MASTER_IP

# update the kube-apiserver settings
ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@${MASTER_IP} <<END_SSH
sudo sed -i '/^    - --service-account-key-file.*$/a\    - --service-account-issuer=kubernetes.default.svc' /etc/kubernetes/manifests/kube-apiserver.yaml
sudo sed -i '/^    - --service-account-key-file.*$/a\    - --service-account-signing-key-file=\/etc\/kubernetes\/pki\/sa.key' /etc/kubernetes/manifests/kube-apiserver.yaml
END_SSH

export KUBECONFIG=./generated/clus_kfg
hpecp k8scluster admin-kube-config ${CLUS_ID} > ${KUBECONFIG}

# The change to the API server configuration (above) should have triggered the kube-apiserver to restart
# the kubea-apiserver should only show running time of a few seconds
kubectl get pods --all-namespaces  | grep kube-apiserver

# automatically create PVs
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Should contain line: `local-path (default)   rancher.io/local-path` 
kubectl get sc

# - Download:
#   - https://github.com/mapr/private-kfctl/blob/v1.0.1-branch-mapr/deploy/operator_bootstrap.yaml 
#   - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/kfdef/kfctl_hpc_istio.v1.0.1.yaml
#   - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/kfdef/test_ldap.yaml

# Apply the bootstrap script to deploy the operator: 
kubectl apply -f operator_bootstrap.yaml

# Install the default services that are specified in 
kubectl apply -f kfctl_hpc_istio.v1.0.1.yaml

# Wait until the auth namespace has been created
watch kubectl get ns

# Deploy the test LDAP service: 
kubectl apply -f test_ldap.yaml

### ^ This fails with:
### Error from server (NotFound): error when creating "test_ldap.yaml": namespaces "auth" not found

# this step is needed because for some reason the dex service doesn't understand that config map is changed
kubectl rollout restart deployment dex -n auth

export NAMESPACE=istio-system
kubectl port-forward -n ${NAMESPACE} svc/istio-ingressgateway 8080:80
```
 
