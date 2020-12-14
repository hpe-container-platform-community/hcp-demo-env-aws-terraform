## Data Fabric - Edge Core Cloud Demo

### Overview

This section describes how to create the demo that is available on [BrightTalk](https://www.brighttalk.com/webcast/12641/445912/stretching-hpe-ezmeral-data-fabric-from-edge-to-cloud) (demo starts around 32 mins 10 seconds).


### Prerequisites

- Active Directory server needs to have been installed and running
- You have downloaded the application code: https://github.com/snowch/data-fabric-edge-core-cloud/archive/master.zip to your terraform project foldder
   - If you don't have access contact chris dot snow at hpe dot com
- You have the cluster IP addresses: `./bin/ec2_instance_status.sh`

### Create MAPR HQ and Edge Infastructure

- Ensure you have the following in your `etc/bluedata_infra.tfvars`:

```
mapr_cluster_1_count         = 3
mapr_cluster_1_name          = "dc1.enterprise.org"
mapr_cluster_2_count         = 3
mapr_cluster_2_name          = "edge1.enterprise.org"
```

And then run `./bin/terraform_apply.sh` to create the AWS infrastructure for MAPR

### Install and Setup MAPR

```
./scripts/end_user_scripts/standalone_mapr/setup_mapr.sh
```

### Register License

```
./scripts/end_user_scripts/standalone_mapr/register_license.sh
```

### Setup Edge Demo

```
./scripts/end_user_scripts/standalone_mapr/setup_edge_demo.sh
```

### Run HQ Dashboard

- Open a New terminal, then

```
./bin/mapr_edge_demo_hq_start.sh
```

### Get HQ Dashboard and MCS URLs

```
./bin/mapr_edge_demo_hq_urls.sh
```

### Run Edge Dashboard

- Open a New terminal, then

```
./bin/mapr_edge_demo_edge_start.sh
```

### Get Edge Dashboard and MCS URLs

```
./bin/mapr_edge_demo_edge_urls.sh
```

### Setup Mirroring, Replication, etc

- Open a New terminal, then

```
./bin/mapr_edge_demo_poststartup_edge_replica.sh
./bin/mapr_edge_demo_poststartup_mirror.sh
./bin/mapr_edge_demo_poststartup_auditing.sh
```

### Restart Volume Mirror

- After requesting assets on the Edge dashbaord, restart mirroring with

```
./bin/mapr_edge_demo_restart_vol_mirror.sh
```

### Monitor Mirroring

- Monitor DC files

Open a new terminal and run:

```
./generated/ssh_mapr_cluster_1_host_0.sh \
   "bash -c 'watch ls -lr /mapr/dc1.enterprise.org/apps/pipeline/data/files-missionX'"
```

- Monitor EDGE files

Open a new terminal and run:

```
./generated/ssh_mapr_cluster_2_host_0.sh \
   "bash -c 'watch ls -lr /mapr/edge1.enterprise.org/apps/pipeline/data/files-missionX'"
```
