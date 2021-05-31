- Add hosts with 'istio-ingressgateway=true'
- Create a K8S cluster with istio addon

### Install KNATIVE

Follow: https://knative.dev/docs/install/install-serving-with-yaml/

- Install the [serving components](https://knative.dev/docs/install/install-serving-with-yaml/#install-the-serving-component)

```
kubectl apply -f https://github.com/knative/serving/releases/download/v0.23.0/serving-crds.yaml
kubectl apply -f https://github.com/knative/serving/releases/download/v0.23.0/serving-core.yaml
```

- Install the [Knative Istio controller](https://knative.dev/docs/install/install-serving-with-yaml/#install-a-networking-layer) (don't install istio as we have installed it as an addon)

```
kubectl apply -f https://github.com/knative/net-istio/releases/download/v0.23.0/net-istio.yaml
```

- Retrieve the ISTIO host IPs

```
kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[*].status.hostIP}'
```

- Configure DNS (adapted from [read DNS](https://knative.dev/docs/install/install-serving-with-yaml/#configure-dns))

  - Update ` modules/module-network/main-dns-knative.tf` with the IPs from the previous step
  - Run `./bin/terraform_apply.sh` to apply the DNS changes
  - Patch knative:

```
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"knative.samdom.example.com":""}}'
```

### Install the knative CLI

- SSH into the RDP server `./bin/ssh_rdp_linux_server.sh`
- Install the CLI

```
wget https://storage.googleapis.com/knative-nightly/client/latest/kn-linux-amd64
sudo mv kn-linux-amd64 /usr/local/bin/kn
sudo chmod +x /usr/local/bin/kn
```
  
### Run serving example

From: https://knative.dev/docs/serving/samples/hello-world/helloworld-python/

All of the following steps are performed on the RDP server.

SSH into the RDP server `./bin/ssh_rdp_linux_server.sh`


#### Build example

```
git clone -b "release-0.23" https://github.com/knative/docs knative-docs
cd knative-docs/docs/serving/samples/hello-world/helloworld-python

# Build the container on your local machine (swap username with your docker repo username)
docker build -t {username}/helloworld-python .

# Push the container to docker registry (swap username with your docker repo username)
docker push {username}/helloworld-python
```

#### Deploy example

```
kn service create helloworld-python --image=docker.io/{username}/helloworld-python --env TARGET="Python Sample v1"
```

#### Verify example

```
kn service describe helloworld-python -o url
```

#### Run example

```
curl $(kn service describe helloworld-python -o url)
```