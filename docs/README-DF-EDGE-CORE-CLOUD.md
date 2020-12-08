### Data Fabric - Edge Core Cloud Demo


### Prerequisites

- You have the application code: `data-fabric-edge-core-cloud-master.zip`

### Create MAPR HQ Cluster

- Ensure you have the following in your `etc/bluedata_infra.tfvars`:

```
mapr_cluster_1_count         = 3
mapr_cluster_1_name          = "dc1.enterprise.org"
```

- Run `./bin/terraform_apply.sh`
- Run `./scripts/mapr_install.sh 1`
- Run `./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 1`

### Create MAPR Edge Cluster

- Ensure you have the following in your `etc/bluedata_infra.tfvars`:

```
mapr_cluster_2_count         = 3
mapr_cluster_2_name          = "edge1.enterprise.org"
```

- Run `./bin/terraform_apply.sh`
- Run `./scripts/mapr_install.sh 2`
- Run `./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 2`

### HQ <--> Edge Passwordless SSH

Run this from your terraform project folder (paste and run these blocks separately):

```
./generated/ssh_mapr_cluster_1_host_0.sh "sudo -u mapr bash -c '[[ -d /home/mapr/.ssh ]] || mkdir /home/mapr/.ssh && chmod 700 /home/mapr/.ssh'" && \
./generated/ssh_mapr_cluster_1_host_0.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa'" < generated/controller.prv_key && \
./generated/ssh_mapr_cluster_1_host_0.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa.pub'" < generated/controller.pub_key && \
./generated/ssh_mapr_cluster_1_host_0.sh "sudo -u mapr bash -c 'chmod 600 /home/mapr/.ssh/id_rsa'" && \
./generated/ssh_mapr_cluster_1_host_0.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/authorized_keys'" < generated/controller.pub_key ;
```

```
./generated/ssh_mapr_cluster_1_host_1.sh "sudo -u mapr bash -c '[[ -d /home/mapr/.ssh ]] || mkdir /home/mapr/.ssh && chmod 700 /home/mapr/.ssh'" && \
./generated/ssh_mapr_cluster_1_host_1.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa'" < generated/controller.prv_key && \
./generated/ssh_mapr_cluster_1_host_1.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa.pub'" < generated/controller.pub_key && \
./generated/ssh_mapr_cluster_1_host_1.sh "sudo -u mapr bash -c 'chmod 600 /home/mapr/.ssh/id_rsa'" && \
./generated/ssh_mapr_cluster_1_host_1.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/authorized_keys'" < generated/controller.pub_key ;
```

```
./generated/ssh_mapr_cluster_1_host_2.sh "sudo -u mapr bash -c '[[ -d /home/mapr/.ssh ]] || mkdir /home/mapr/.ssh && chmod 700 /home/mapr/.ssh'" && \
./generated/ssh_mapr_cluster_1_host_2.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa'" < generated/controller.prv_key && \
./generated/ssh_mapr_cluster_1_host_2.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa.pub'" < generated/controller.pub_key && \
./generated/ssh_mapr_cluster_1_host_2.sh "sudo -u mapr bash -c 'chmod 600 /home/mapr/.ssh/id_rsa'" && \
./generated/ssh_mapr_cluster_1_host_2.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/authorized_keys'" < generated/controller.pub_key ;
```

```
./generated/ssh_mapr_cluster_2_host_0.sh "sudo -u mapr bash -c '[[ -d /home/mapr/.ssh ]] || mkdir /home/mapr/.ssh && chmod 700 /home/mapr/.ssh'" && \
./generated/ssh_mapr_cluster_2_host_0.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa'" < generated/controller.prv_key && \
./generated/ssh_mapr_cluster_2_host_0.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa.pub'" < generated/controller.pub_key && \
./generated/ssh_mapr_cluster_2_host_0.sh "sudo -u mapr bash -c 'chmod 600 /home/mapr/.ssh/id_rsa'" && \
./generated/ssh_mapr_cluster_2_host_0.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/authorized_keys'" < generated/controller.pub_key ;

./generated/ssh_mapr_cluster_2_host_1.sh "sudo -u mapr bash -c '[[ -d /home/mapr/.ssh ]] || mkdir /home/mapr/.ssh && chmod 700 /home/mapr/.ssh'" && \
./generated/ssh_mapr_cluster_2_host_1.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa'" < generated/controller.prv_key && \
./generated/ssh_mapr_cluster_2_host_1.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa.pub'" < generated/controller.pub_key && \
./generated/ssh_mapr_cluster_2_host_1.sh "sudo -u mapr bash -c 'chmod 600 /home/mapr/.ssh/id_rsa'" && \
./generated/ssh_mapr_cluster_2_host_1.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/authorized_keys'" < generated/controller.pub_key ;
```

```
./generated/ssh_mapr_cluster_2_host_2.sh "sudo -u mapr bash -c '[[ -d /home/mapr/.ssh ]] || mkdir /home/mapr/.ssh && chmod 700 /home/mapr/.ssh'" && \
./generated/ssh_mapr_cluster_2_host_2.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa'" < generated/controller.prv_key && \
./generated/ssh_mapr_cluster_2_host_2.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/id_rsa.pub'" < generated/controller.pub_key && \
./generated/ssh_mapr_cluster_2_host_2.sh "sudo -u mapr bash -c 'chmod 600 /home/mapr/.ssh/id_rsa'" && \
./generated/ssh_mapr_cluster_2_host_2.sh "sudo -u mapr bash -c 'cat > /home/mapr/.ssh/authorized_keys'" < generated/controller.pub_key ;
```

### Configure cross-cluster security

- Run from the terraform project folder:

```
./generated/ssh_mapr_cluster_1_host_0.sh "sudo -u mapr bash -c 'cat > /tmp/localmaprhosts'" <<< $(terraform output mapr_cluster_1_hosts_private_ip_flat)
./generated/ssh_mapr_cluster_1_host_0.sh "sudo -u mapr bash -c 'cat > /tmp/remotemaprhosts'" <<< $(terraform output mapr_cluster_2_hosts_private_ip_flat)

./generated/ssh_mapr_cluster_1_host_0.sh "sudo apt-get -y install expect pssh"
```

- Run `./generated/ssh_mapr_cluster_1_host_0.sh`

```
# both passwords are `mapr`
sudo -u mapr /opt/mapr/server/configure-crosscluster.sh create all \
   -localuser mapr -localhosts /tmp/localmaprhosts  \
   -remoteuser mapr -remotehosts /tmp/remotemaprhosts \
   -remoteip $(head -n1 /tmp/remotemaprhosts)

# verify with
maprlogin password -cluster edge1.enterprise.org
```

### Setup HQ Dashboard

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

### Setup Edge Dashboard

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
./installDemo.sh edge
./runDashboard.sh edge
```
