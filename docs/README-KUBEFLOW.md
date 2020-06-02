THIS DOCUMENT IS A WORK IN PROGRESS
-----

### Kubeflow Install steps

Execute the below script if creating a new environment with terraform managed

- Have a least 2 worker hosts
- Use HPECP 5.1 (1289+ engineering build)

```bash
./bin/create_new_environment_from_scratch.sh

./bin/experimental/01_configure_global_active_directory.sh
./bin/experimental/02_gateway_add.sh
./bin/experimental/03_k8sworkers_add.sh
```

Create a k8s cluster:

```
# install the cli
pip3 install --quiet --upgrade git+https://github.com/hpe-container-platform-community/hpecp-client@master

# configure the cli
hpecp configure-cli

# test the cli - should return your platform id
hpecp license platform-id 

hpecp k8sworker list
# +-----------+--------+------------------------------------------+------------+---------------------------+
# | worker_id | status |                 hostname                 |   ipaddr   |           href            |
# +-----------+--------+------------------------------------------+------------+---------------------------+
# |    3      | ready  | ip-10-1-0-178.us-west-2.compute.internal | 10.1.0.178 | /api/v2/worker/k8shost/3  |
# |    4      | ready  | ip-10-1-0-93.us-west-2.compute.internal  | 10.1.0.93  | /api/v2/worker/k8shost/4  |
# +-----------+--------+------------------------------------------+------------+---------------------------+

# get the HPE CP supported k8s 1.18.x version number
KVERS=$(hpecp k8scluster k8s-supported-versions --output text --major-filter 1 --minor-filter 18)
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
ping -c 5 $MASTER_IP
```
If ping fails start the vpn:

```
./generated/vpn_server_setup.sh
sudo ./generated/vpn_mac_connect.sh
```

Now setup the k8s cluster api-server:

```
# update the kube-apiserver settings
ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@${MASTER_IP} <<END_SSH
sudo sed -i '/^    - --service-account-key-file.*$/a\    - --service-account-issuer=kubernetes.default.svc' /etc/kubernetes/manifests/kube-apiserver.yaml
sudo sed -i '/^    - --service-account-key-file.*$/a\    - --service-account-signing-key-file=\/etc\/kubernetes\/pki\/sa.key' /etc/kubernetes/manifests/kube-apiserver.yaml
END_SSH

export KUBECONFIG=./generated/${CLUS_NAME}.conf
hpecp k8scluster admin-kube-config ${CLUS_ID} > ${KUBECONFIG}

# The change to the API server configuration (above) should have triggered the kube-apiserver to restart
# the kubea-apiserver should only show running time of a few seconds
kubectl get pods -n kube-system -l component=kube-apiserver
```

Now define PVs and apply the kubeflow scripts:

```
# automatically create PVs
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass default -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# Should contain line: `local-path (default)   rancher.io/local-path` 
kubectl get sc
```

- Download:
   - https://github.com/mapr/private-kfctl/blob/v1.0.1-branch-mapr/deploy/operator_bootstrap.yaml 
   - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/kfdef/kfctl_hpc_istio.v1.0.1.yaml
   - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/utils/test_ldap.yaml

```
# Apply the bootstrap script to deploy the operator: 
kubectl apply -f operator_bootstrap.yaml

sleep 300
```
Now setup istio, etc.

```
# Install the default services that are specified in 
kubectl apply -f kfctl_hpc_istio.v1.0.1.yaml

# Give install time to start
sleep 300

# Ensure the auth namespace has been created
kubectl get ns auth

# Deploy the test LDAP service: 
kubectl apply -f test_ldap.yaml

# this step is needed because for some reason the dex service doesn't understand that config map is changed
kubectl rollout restart deployment dex -n auth

export NAMESPACE=istio-system
kubectl port-forward -n ${NAMESPACE} svc/istio-ingressgateway 8080:80
```

Open browser:

```
open http://localhost:8080
```
 
