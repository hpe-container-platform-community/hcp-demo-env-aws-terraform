THIS DOCUMENT IS A WORK IN PROGRESS
-----

### Kubeflow install steps

It is recommended that you clone a fresh instance of this repository and create a new HPE Container Platform deployment for the Kubeflow installation - see the [quickstart](https://github.com/bluedata-community/bluedata-demo-env-aws-terraform#setup-environment).

- Execute the below scripts to create a new environment with terraform 
  - Define 2 worker hosts: set `worker_count=2` in `./etc/bluedata_infra.tfvars`
  - Use HPECP 5.1 (1289+ engineering build)

```bash
./bin/create_new_environment_from_scratch.sh

./bin/experimental/01_configure_global_active_directory.sh
./bin/experimental/02_gateway_add.sh
./bin/experimental/03_k8sworkers_add.sh
```

- Download the yaml files

   - https://github.com/mapr/private-kfctl/blob/v1.0.1-branch-mapr/deploy/operator_bootstrap.yaml to `./operator_bootstrap.yaml `
   - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/kfdef/kfctl_hpc_istio.v1.0.1.yaml to `./kfctl_hpc_istio.v1.0.1.yaml`
   - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/utils/test_ldap.yaml to `./test_ldap.yaml`


- Connect to the VPN

```
./generated/vpn_server_setup.sh
sudo ./generated/vpn_mac_connect.sh
```

- Run the install script:

```
bash -x  docs/README-KUBEFLOW/install.sh
```

Expose the UI

```
export NAMESPACE=istio-system
kubectl port-forward -n ${NAMESPACE} svc/istio-ingressgateway 8080:80
```

Open browser and login as `ad_admin1` with password `pass123`.

```
open http://localhost:8080
```

- Click Start Setup
- Click Finish

### Known Issues

- Restarting your AWS instances may result in Kubeflow disappearing. For now, reinstall:

```bash
hpecp k8scluster list

# replace with your cluster id from 'hpecp k8scluster list'
CLUSTER_ID=/api/v2/k8scluster/1 

hpecp k8scluster delete $CLUSTER_ID

watch hpecp k8scluster list

bash -x  docs/README-KUBEFLOW/install.sh
```

### Next Steps

- [Hello World](./README-KUBEFLOW/HELLO-WORLD.md)
