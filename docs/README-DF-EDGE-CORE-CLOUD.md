## Data Fabric - Edge Core Cloud Demo

### Overview

This section describes how to create the demo that is available on [BrightTalk](https://www.brighttalk.com/webcast/12641/445912/stretching-hpe-ezmeral-data-fabric-from-edge-to-cloud) (demo starts around 32 mins 10 seconds).


### Prerequisites

- Active Directory server needs to have been installed and running
- You have downloaded the application code: https://github.com/snowch/data-fabric-edge-core-cloud/archive/master.zip
   - If you don't have access contact chris dot snow at hpe dot com
- You have the cluster IP addresses: `./bin/ec2_instance_status.sh`

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

```
nohup $(pwd)/scripts/mapr_install.sh 1 > nohup1.out &
nohup $(pwd)/scripts/mapr_install.sh 2 > nohup2.out &
tail -f nohup1.out nohup2.out
# CTRL-C when finished

nohup $(pwd)/scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 1 >> nohup1.out &
nohup $(pwd)/scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 2 >> nohup2.out &
tail -f nohup1.out nohup2.out
# CTRL-C when finished
```

### Configure cross-cluster security

- Run from the terraform project folder.  

IMPORTANT: Copy and paste each block separately.

```
DC_MAPR_USERTICKET="$(./generated/ssh_mapr_cluster_1_host_0.sh 'sudo head -n1 /opt/mapr/conf/mapruserticket')"
echo "$DC_MAPR_USERTICKET"
```

```
EDGE_MAPR_USERTICKET="$(./generated/ssh_mapr_cluster_2_host_0.sh 'sudo head -n1 /opt/mapr/conf/mapruserticket')"
echo "$EDGE_MAPR_USERTICKET"
```

```
for I in 1 2; do
   echo "$DC_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_1_host_$I.sh "sudo bash -c 'cat > /opt/mapr/conf/mapruserticket'"

   echo "$EDGE_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_2_host_$I.sh "sudo bash -c 'cat > /opt/mapr/conf/mapruserticket'"
done;
```

```
for I in 0 1 2; do
   echo "$DC_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_2_host_$I.sh "sudo bash -c 'cat >> /opt/mapr/conf/mapruserticket'"
      
   echo "$EDGE_MAPR_USERTICKET" | \
      ./generated/ssh_mapr_cluster_1_host_$I.sh "sudo bash -c 'cat >> /opt/mapr/conf/mapruserticket'"
done;
```

```
for i in 1 2; do   
  for j in 0 1 2; do    
    echo CLUSTER $i HOST $j;   
    ./generated/ssh_mapr_cluster_${i}_host_${j}.sh "sudo cat /opt/mapr/conf/mapruserticket"
  done;
done;
```

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


### License both clusters

- Login to MCS on both clusters (MCS runs on Host 0)
  - You can find the host external IPs with `./bin/ec2_instance_status.sh`
  - Login to `https://EXTIP:8443` (user:password = mapr:mapr)
  - Navigate to **Admin -> Cluster Settings -> Licenses**
  - Click **Get a Free Trial License**
  - Login or Register
  - Click **Add Cluster**
    - Enter **Cluster ID**
    - Enter **Cluster Name** (dc1.enterprise.org or edge1.enterprise.org)
    - Select M5, M7 License
    - Click **View Key** and copy license 
  - In MCS click **Copy/Paste License**
    - Paste License
    - Click Submit

### Setup HQ Dashboard

- Run the following:

```
# 
# IMPORTANT: Replace `/Users/christophersnow/Downloads` with the location of your zip file
#

./generated/ssh_mapr_cluster_1_host_0.sh \
   "cat > data-fabric-edge-core-cloud-master.zip" < /Users/christophersnow/Downloads/data-fabric-edge-core-cloud-master.zip
```

- Install the dashboard

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
   "sudo -u mapr bash -c 'cd /home/mapr/microservices-dashboard; ./runDashboard.sh hq'"
```

### Setup Edge Dashboard

- Run the following:

```
CLUSTER2_NODE0="$(terraform output mapr_cluster_2_hosts_private_ip_flat | head -n1)"
echo $CLUSTER2_NODE0

./generated/ssh_mapr_cluster_1_host_0.sh \
   "sudo -u mapr bash -c 'scp -o StrictHostKeyChecking=no ./data-fabric-edge-core-cloud-master.zip mapr@${CLUSTER2_NODE0}:~/'"
```

- Verify data-fabric-edge-core-cloud-master.zip has been copied to /home/mapr 

```
./generated/ssh_mapr_cluster_2_host_0.sh \
   "sudo -u mapr ls -l /home/mapr"
```

- Install the dashboard

```
./generated/ssh_mapr_cluster_2_host_0.sh << EOF
   set -e
   sudo service mapr-posix-client-basic restart
   sudo rm -rf /home/mapr/microservices-dashboard
   
   sudo -u mapr bash -c 'unzip -d /home/mapr -o /home/mapr/data-fabric-edge-core-cloud-master.zip'
   sudo -u mapr bash -c 'mv /home/mapr/data-fabric-edge-core-cloud-master /home/mapr/microservices-dashboard'
   sudo -u mapr bash -c 'rm -f /home/mapr/microservices-dashboard/eclipse/microservices-dashboard-app.tar'
   sudo -u mapr bash -c 'cd /home/mapr/microservices-dashboard/eclipse; tar cf microservices-dashboard-app.tar microservices-dashboard/'
   sudo -u mapr bash -c 'cd /home/mapr; echo mapr | maprlogin password -user mapr'
   sudo -u mapr bash -c 'cd /home/mapr/microservices-dashboard; ./installDemo.sh edge'
EOF
```

### Run HQ Dashboard

- Open a new terminal to run the HQ dashboard:

```
./generated/ssh_mapr_cluster_2_host_0.sh \
   "sudo -u mapr bash -c 'cd /home/mapr/microservices-dashboard; EDGE_HOSTNAME=\$(hostname -f) ./runDashboard.sh edge'"
```

### Register services

```
./generated/ssh_mapr_cluster_1_host_0.sh \
   "sudo -u mapr bash -c '. /home/mapr/microservices-dashboard/scripts/hq/create-edge-replica.sh'"
```

```
./generated/ssh_mapr_cluster_2_host_0.sh \
   "sudo -u mapr bash -c '. /home/mapr/microservices-dashboard/scripts/edge/createMirror.sh'"
```

- Setup auditing

```
./generated/ssh_mapr_cluster_2_host_0.sh <<EOF
   sudo -u mapr bash <<BASH_EOF
      set -x
      maprcli config save -values "{\"mfs.enable.audit.as.stream\":\"1\"}"
      maprcli audit data -enabled true -retention 1
      maprcli volume audit -name mapr.apps -enabled true -dataauditops +create,+delete,+tablecreate,-setattr,-chown,-chperm,-chgrp,-getxattr,-listxattr,-setxattr,-removexattr,-read,-write,-mkdir,-readdir,-rmdir,-createsym,-lookup,-rename,-createdev,-truncate,-tablecfcreate,-tablecfdelete,-tablecfmodify,-tablecfScan,-tableget,-tableput,-tablescan,-tableinfo,-tablemodify,-getperm,-getpathforfid,-hardlink
      maprcli volume info -name mapr.apps -json
      hadoop mfs -setaudit on /apps/pipeline/data
      hadoop mfs -ls /apps/pipeline
BASH_EOF
EOF
```

### Monitor

- Monitor DC files

Open a new terminal and run:

```
./generated/ssh_mapr_cluster_1_host_0.sh -t \
   "bash -c 'watch ls -lr /mapr/dc1.enterprise.org/apps/pipeline/data/files-missionX'"
```

- Monitor EDGE files

Open a new terminal and run:

```
./generated/ssh_mapr_cluster_2_host_0.sh -t \
   "bash -c 'watch ls -lr /mapr/edge1.enterprise.org/apps/pipeline/data/files-missionX'"
```

### Manually restart volume replication

Open a new terminal and run:

```
./generated/ssh_mapr_cluster_2_host_0.sh <<EOF
   sudo -u mapr bash <<BASH_EOF
   set -x
   maprcli volume mirror stop -name files-missionX
   maprcli volume mirror start -name files-missionX
BASH_EOF
EOF
```
