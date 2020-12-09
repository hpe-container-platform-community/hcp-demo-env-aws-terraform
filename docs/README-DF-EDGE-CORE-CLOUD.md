### Data Fabric - Edge Core Cloud Demo


### Prerequisites

- Active Directory server needs to have been installed and running
- You have downloaded the application code: `data-fabric-edge-core-cloud-master.zip`

### Create MAPR HQ and Edge Cluster

- Ensure you have the following in your `etc/bluedata_infra.tfvars`:

```
mapr_cluster_1_count         = 3
mapr_cluster_1_name          = "dc1.enterprise.org"
mapr_cluster_2_count         = 3
mapr_cluster_2_name          = "edge1.enterprise.org"
```

And then run `./bin/terraform_apply.sh` to create the AWS infrastructure for MAPR

- Run the following from your terraform project folder:

If you have TMUX installed (recommended):

```
wget https://gist.githubusercontent.com/snowch/03a374bfa7a8b1923ef8cc8e172e0819/raw/3fe69641800606ca3ced3e81582459481592de1d/tmux-sync.sh
chmod +x tmux-sync.sh
./tmux-sync.sh mapr-install "./scripts/mapr_install.sh 1" "./scripts/mapr_install.sh 2"

# ctrl-D to quit tmux sessions when they have finished

./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 1
./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 2
```

If you don't have tmux installed:

```
./scripts/mapr_install.sh 1
./scripts/mapr_install.sh 2
./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 1
./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 2
```

### Configure cross-cluster security

- Run from the terraform project folder:

```
terraform output mapr_cluster_1_hosts_private_ip_flat > localmaprhosts
terraform output mapr_cluster_2_hosts_private_ip_flat > remotemaprhosts

./generated/ssh_mapr_cluster_1_host_0.sh \
   "sudo -u mapr bash -c 'cat > /tmp/localmaprhosts && cat /tmp/localmaprhosts'" < localmaprhosts
   
./generated/ssh_mapr_cluster_1_host_0.sh \
   "sudo -u mapr bash -c 'cat > /tmp/remotemaprhosts && cat /tmp/remotemaprhosts'" < remotemaprhosts

./generated/ssh_mapr_cluster_1_host_0.sh "sudo apt-get -y install expect pssh"

printf "mapr\nmapr" | ./generated/ssh_mapr_cluster_1_host_0.sh -t \
   "sudo -u mapr bash -c '/opt/mapr/server/configure-crosscluster.sh create all \
      -localuser mapr -localhosts /tmp/localmaprhosts \
      -remoteuser mapr -remotehosts /tmp/remotemaprhosts \
      -remoteip $(terraform output mapr_cluster_2_hosts_private_ip_flat | head -n1)'"
```

- Verify HQ can connect to EDGE:

```
echo mapr | ./generated/ssh_mapr_cluster_1_host_0.sh -t \
   sudo -u mapr maprlogin password -cluster edge1.enterprise.org
```

This should report:

> MapR credentials of user 'mapr' for cluster 'edge1.enterprise.org' are written to '/tmp/maprticket_5000'


- Verify EDGE can connect to HQ:

```
echo mapr | ./generated/ssh_mapr_cluster_2_host_0.sh -t \
   sudo -u mapr maprlogin password -cluster dc1.enterprise.org
```

This should report:

> MapR credentials of user 'mapr' for cluster 'dc1.enterprise.org' are written to '/tmp/maprticket_5000'


### Setup HQ Dashboard

- Run the following:

```
# 
# IMPORTANT: Replace `/Users/christophersnow/Downloads` with the location of your zip file)
#

./generated/ssh_mapr_cluster_1_host_0.sh \
   "cat > data-fabric-edge-core-cloud-master.zip" < /Users/christophersnow/Downloads/data-fabric-edge-core-cloud-master.zip
```

```
./generated/ssh_mapr_cluster_1_host_0.sh << EOF
   set -e
   sudo service mapr-posix-client-basic restart
   sudo cp -f /home/ubuntu/data-fabric-edge-core-cloud-master.zip /home/mapr/
   sudo chown mapr:mapr /home/mapr/data-fabric-edge-core-cloud-master.zip
   sudo rm -rf /home/mapr/microservices-dashboard
   sudo -u mapr bash -c 'cd /home/mapr; unzip -d /home/mapr -o /home/mapr/data-fabric-edge-core-cloud-master.zip'
   sudo -u mapr bash -c 'cd /home/mapr; mv data-fabric-edge-core-cloud-master microservices-dashboard'
   sudo -u mapr bash -c 'cd /home/mapr; echo mapr | maprlogin password -user mapr'
   sudo -u mapr bash -c 'cd /home/mapr/microservices-dashboard; ./installDemo.sh hq'
EOF
```

### Run HQ Dashboard

- Open a new terminal to run the HQ dashboard:

```
./generated/ssh_mapr_cluster_1_host_0.sh \
   sudo -u mapr "/home/mapr/microservices-dashboard/runDashboard.sh hq"
```

### Setup Edge Dashboard

- Run `./generated/ssh_mapr_cluster_2_host_0.sh "cat > data-fabric-edge-core-cloud-master.zip" < /Users/christophersnow/Downloads/data-fabric-edge-core-cloud-master.zip` (replace /Users/christophersnow/Downloads with the location of your zip file)
- SSH into the MAPR Cluster `./generated/ssh_mapr_cluster_2_host_0.sh`, then:



```console
sudo service mapr-posix-client-basic restart
sudo mv ~/data-fabric-edge-core-cloud-master.zip /home/mapr/
sudo chown mapr:mapr /home/mapr/data-fabric-edge-core-cloud-master.zip

sudo -E -u mapr bash <<EOF
cd /home/mapr
unzip /home/mapr/data-fabric-edge-core-cloud-master.zip
mv data-fabric-edge-core-cloud-master microservices-dashboard
echo mapr | maprlogin password -user mapr
cd microservices-dashboard/eclipse
rm microservices-dashboard-app.tar
tar cf microservices-dashboard-app.tar microservices-dashboard/
./installDemo.sh edge
EOF

sudo -u mapr bash -c "cd /home/mapr/microservices-dashboard && EDGE_HOSTNAME=$(hostname -f) ./runDashboard.sh edge"
```

### License both clusters

- TODO

### Register services

```
./generated/ssh_mapr_cluster_1_host_0.sh \
   "sudo -u mapr bash -c '. /home/mapr/microservices-dashboard/scripts/hq/create-edge-replica.sh'"
```

```
./generated/ssh_mapr_cluster_2_host_0.sh \
   "sudo -u mapr bash -c 'echo mapr | maprlogin password -user mapr -cluster dc1.enterprise.org'"
```

```
./generated/ssh_mapr_cluster_2_host_0.sh \
   "sudo -u mapr bash -c '. /home/mapr/microservices-dashboard/scripts/edge/createMirror.sh'"
```
