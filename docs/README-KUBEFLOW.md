THIS DOCUMENT IS A WORK IN PROGRESS
-----

### Kubeflow

#### Pre-requisites

- [VPN Setup and Connected](https://github.com/bluedata-community/bluedata-demo-env-aws-terraform/blob/master/docs/README-VPN.md)

#### Install steps

- Deploy a 5.1 (E.g. 1289+ Engineering Build) HPE Container Platform Environment
- This can run on your client machine:

```bash
# Install a fresh Environment of HPECP 5.1 (1289+ engineering build)
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

# get the latest 17x version number
KVERS=$(hpecp httpclient get /api/v2/k8smanifest |  python3 -c 'import json,sys;obj=json.load(sys.stdin);  [ print(v) for v in obj["version_info"] if v.startswith("1.17") ]')
echo $KVERS

# replace IDs defined below with the ones from `hpecp k8sworker list'
MASTER_ID="/api/v2/worker/k8shost/16"
WORKER_ID="/api/v2/worker/k8shost/17"
MASTER_IP="10.1.0.178"

# create a K8s Cluster
CLUS_ID=$(hpecp k8scluster create clus1 ${MASTER_ID}:master,${WORKER_ID}:worker --k8s-version $KVERS)
echo $CLUS_ID

# wait until ready
watch hpecp k8scluster list

# check connectivity to server (may need to start vpn)
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
watch kubectl get pods --all-namespaces  | grep kube-apiserver

# automatically create PVs
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Should contain line: `local-path (default)   rancher.io/local-path` 
kubectl get sc

# - Download:
#   - https://github.com/mapr/private-kfctl/blob/v1.0.1-branch-mapr/deploy/operator_bootstrap.yaml 
#   - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/kfdef/kfctl_hpc_istio.v1.0.1.yaml
#   - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/kfdef/test_ldap.yaml

# Create auth namespace 
kubectl create namespace auth

# Apply the bootstrap script to deploy the operator: 
kubectl apply -f operator_bootstrap.yaml

# Install the default services that are specified in 
kubectl apply -f kfctl_hpc_istio.v1.0.1.yaml

# Deploy the test LDAP service: 
kubectl apply -f test_ldap.yaml

# this step is needed because for some reason the dex service doesn't understand that config map is changed
kubectl rollout restart deployment dex -n auth
```
 
