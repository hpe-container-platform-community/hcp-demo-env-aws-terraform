THIS DOCUMENT IS A WORK IN PROGRESS
-----

### Kubeflow

#### Pre-requisites

- Installed RDP Host

#### Install steps

- Deploy a 5.1 (E.g. 1289+ Engineering Build) HPE Container Platform Environment
- Deploy a 1.18+ Cluster (I used 1 x Master and 1 x Worker nodes)
- SSH into Master Host:
  - Add 2 lines to `/etc/kubernetes/manifests/kube-apiserver.yaml`.
    - `- --service-account-issuer=kubernetes.default.svc`
    - `- --service-account-signing-key-file=/etc/kubernetes/pki/sa.key`
- On your client machine (or RDP host):
  - Install HPECP CLI: `pip3 install --quiet --upgrade git+https://github.com/hpe-container-platform-community/hpecp-client@master`
  - Configure HPCP CLI: `hpecp configure-cli`
  - Retrieve List of K8S Clusters: `hpecp k8scluster list` (note the cluster ID)
  - Retrieve Kubectl admin config: `hpecp k8scluster admin_kube_config /api/v2/k8scluster/4 > ./clus_kfg` (use the cluster ID from the previous step)
  - Get the kube-apiserver pod name: `KUBECONFIG=./clus_kfg kubectl get pods --all-namespaces  | grep kube-apiserver` (note the full name of the pod)
  - Restart the pod: `KUBECONFIG=./clus_kfg kubectl delete pod -n kube-system kube-apiserver-ip-10-1-0-178.us-west-2.compute.internal` (replace with the name from the previous step)

- If you want PVs to be automatically created:
  - Run: `KUBECONFIG=./clus_kfg kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml`
  - Make storage class with provisioner as default `KUBECONFIG=./clus_kfg kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'`
  - Check with: `KUBECONFIG=./clus_kfg kubectl get sc`.  Should contain line: `local-path (default)   rancher.io/local-path`      

- Download:
  - https://github.com/mapr/private-kfctl/blob/v1.0.1-branch-mapr/deploy/operator_bootstrap.yaml 
  - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/kfdef/kfctl_hpc_istio.v1.0.1.yaml
  - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/kfdef/test_ldap.yaml

- Create auth namespace `KUBECONFIG=./clus_kfg kubectl create namespace auth`
- Apply the bootstrap script to deploy the operator: 
  - `KUBECONFIG=./clus_kfg kubectl apply -f operator_bootstrap.yaml`
-  Install the default services that are specified in 
  - `KUBECONFIG=./clus_kfg kubectl apply -f kfctl_hpc_istio.v1.0.1.yaml`
- Deploy the test LDAP service: 
  - `KUBECONFIG=./clus_kfg kubectl apply -f test_ldap.yaml`
- `KUBECONFIG=./clus_kfg kubectl rollout restart deployment dex -n auth ` - this step is needed because for some reason the dex service doesn't understand that config map is changed

### Complete script (for terraform users)

This can run on your client machine

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

ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@${MASTER_IP} <<END_SSH
sudo sed -i '/^    - --service-account-key-file.*$/a\    - --service-account-issuer=kubernetes.default.svc' /etc/kubernetes/manifests/kube-apiserver.yaml
sudo sed -i '/^    - --service-account-key-file.*$/a\    - --service-account-signing-key-file=\/etc\/kubernetes\/pki\/sa.key' /etc/kubernetes/manifests/kube-apiserver.yaml
END_SSH

export KUBECONFIG=./generated/clus_kfg
hpecp k8scluster admin-kube-config ${CLUS_ID} > ${KUBECONFIG}
kubectl get pods --all-namespaces  | grep kube-apiserver

# The change to the API server should have triggered the kube-apiserver to restart and should only show running time of a few seconds

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
 
