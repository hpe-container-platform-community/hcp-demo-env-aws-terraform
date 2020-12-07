### Data Fabric - Edge Core Cloud Demo


### Prerequisites

- You have the application code: `data-fabric-edge-core-cloud-master.zip`

### HQ Setup

#### Create MAPR HQ Cluster

- Ensure you have the following in your `etc/bluedata_infra.tfvars`:

```
mapr_cluster_1_count         = 3
mapr_cluster_1_name          = "dc1.enterprise.org"
```

- Run `./bin/terraform_apply.sh`
- Run `./scripts/mapr_install.sh 1`
- Run `./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 1`

#### Setup HQ Dashboard

- Run `./generated/ssh_mapr_cluster_1_host_0.sh "cat > data-fabric-edge-core-cloud-master.zip" < /Users/christophersnow/Downloads/data-fabric-edge-core-cloud-master.zip` (replace /Users/christophersnow/Downloads with the location of your zip file)
- SSH into the MAPR Cluster `./generated/ssh_mapr_cluster_1_host_0.sh`, then:

```console
sudo service mapr-posix-client-basic restart
sudo mv ~/data-fabric-edge-core-cloud-master.zip /home/mapr/
sudo chown mapr:mapr /home/mapr/data-fabric-edge-core-cloud-master.zip
sudo su - mapr
bash
unzip /home/mapr/data-fabric-edge-core-cloud-master.zip
mv data-fabric-edge-core-cloud-master microservices-dashboard
echo mapr | maprlogin password -user mapr
cd microservices-dashboard
./installDemo.sh hq
./runDashboard.sh hq
```

### Edge Setup

#### Create MAPR Edge Cluster

- Ensure you have the following in your `etc/bluedata_infra.tfvars`:

```
mapr_cluster_2_count         = 3
mapr_cluster_2_name          = "edge1.enterprise.org"
```

- Run `./bin/terraform_apply.sh`
- Run `./scripts/mapr_install.sh 2`
- Run `./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 2`

#### Setup Edge Dashboard

- Run `./generated/ssh_mapr_cluster_2_host_0.sh "cat > data-fabric-edge-core-cloud-master.zip" < /Users/christophersnow/Downloads/data-fabric-edge-core-cloud-master.zip` (replace /Users/christophersnow/Downloads with the location of your zip file)
- SSH into the MAPR Cluster `./generated/ssh_mapr_cluster_2_host_0.sh`, then:

```console
sudo service mapr-posix-client-basic restart
sudo mv ~/data-fabric-edge-core-cloud-master.zip /home/mapr/
sudo chown mapr:mapr /home/mapr/data-fabric-edge-core-cloud-master.zip
sudo su - mapr
bash
unzip /home/mapr/data-fabric-edge-core-cloud-master.zip
mv data-fabric-edge-core-cloud-master microservices-dashboard
echo mapr | maprlogin password -user mapr
cd microservices-dashboard
./installDemo.sh hq
./runDashboard.sh hq
```


#### K8S DataTap Setup (optional)

- Retrieve the tenant ID
- Run `./scripts/end_user_scripts/standalone_mapr/setup_datatap_5.1.sh $TENANT_ID /`
