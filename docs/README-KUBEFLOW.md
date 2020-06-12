THIS DOCUMENT IS A WORK IN PROGRESS
-----

### Recommended watching

[Kubeflow 101 playlist - 5 videos](https://www.youtube.com/watch?v=cTZArDgbIWw&list=PLIivdWyY5sqLS4lN75RPDEyBgTro_YX7x) [approx. 20 mins total]

### Kubeflow install steps

It is recommended that you clone a fresh instance of this repository and create a new HPE Container Platform deployment for the Kubeflow installation - see the [quickstart](https://github.com/bluedata-community/bluedata-demo-env-aws-terraform#setup-environment).

- Execute the below scripts to create a new environment with terraform 
  - Define 2 worker hosts: set `worker_count=2` in `./etc/bluedata_infra.tfvars`
  - Use HPECP 5.1 (1289 or 1440 engineering build) - Chris Snow can provide the URL.

```bash
./bin/create_new_environment_from_scratch.sh

./bin/experimental/01_configure_global_active_directory.sh
./bin/experimental/02_gateway_add.sh
./bin/experimental/03_k8sworkers_add.sh
```

- Download the yaml files to the terraform project root directory

   - https://github.com/mapr/private-kfctl/blob/v1.0.1-branch-mapr/deploy/operator_bootstrap.yaml to `./operator_bootstrap.yaml `
   - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/kfdef/kfctl_hpc_istio.v1.0.1.yaml to `./kfctl_hpc_istio.v1.0.1.yaml`
   - https://github.com/mapr/private-manifests/blob/v1.0.1-branch-mapr/utils/test_ldap.yaml to `./test_ldap.yaml`


- Connect to the VPN

```
./generated/vpn_server_setup.sh
sudo ./generated/vpn_mac_connect.sh # Windows/Linux users - see https://preview.tinyurl.com/ycfqvrgy
```

- Run the install script (if you have created a new HPE CP environment with 2 workers, you don't need to modify the script):

```
export HPECP_CONFIG_FILE=./generated/hpecp.conf
bash -x  docs/README-KUBEFLOW/install.sh
```

### Expose the UI and Login

```
export KUBECONFIG=./generated/kubeflow_cluster.conf
export NAMESPACE=istio-system
kubectl port-forward -n ${NAMESPACE} svc/istio-ingressgateway 8080:80

# If you recieve an error such as the following:
#
#    Unable to connect to the server: \
#       dial tcp: lookup ip-10-1-0-185.us-west-2.compute.internal: no such host
#
# Ensure you are only connected to terraform managed vpn and not any other vpn such as Pulse.
```

Open browser and login as `ad_admin1` with password `pass123`.

```
open http://localhost:8080
```

- Click Start Setup
- Click Finish

### Reconnecting after worker host reboot

- Restarting your AWS instances may result in Kubeflow failing to properly restart. Wait around 10 minutes before running the steps to [Expose the UI and Login](#expose-the-ui-and-login).  If after this time you are still unable to portforward, run:

```bash
bash -x  docs/README-KUBEFLOW/after_worker_restart.sh
```

After running the above script, proceed to the step [Expose the UI and Login](#expose-the-ui-and-login)

### Next Steps

- Familiarise yourself with the main Kubeflow [Components](https://www.kubeflow.org/docs/components/) and [Use Cases](https://www.kubeflow.org/docs/about/use-cases/)
- [Hello World notebook](./README-KUBEFLOW/HELLO-WORLD-NOTEBOOK.md)
- [Hello World pipeline](./README-KUBEFLOW/HELLO-WORLD-PIPELINE.md)
- [Hello World training](./README-KUBEFLOW/HELLO-WORLD-TF-TRAINING.md)
