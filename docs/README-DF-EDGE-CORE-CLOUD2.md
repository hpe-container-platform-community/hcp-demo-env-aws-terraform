## Data Fabric - Edge Core Cloud Demo

### Overview

This section describes how to create the demo that is available on [BrightTalk](https://www.brighttalk.com/webcast/12641/445912/stretching-hpe-ezmeral-data-fabric-from-edge-to-cloud) (demo starts around 32 mins 10 seconds).


### Prerequisites

- Active Directory server needs to have been installed and running
- You have downloaded the application code: https://github.com/snowch/data-fabric-edge-core-cloud/archive/master.zip to your terraform project foldder
   - If you don't have access contact chris dot snow at hpe dot com
- You have the cluster IP addresses: `./bin/ec2_instance_status.sh`

## Setup the demo

### Create MAPR HQ and Edge Infastructure

- Ensure you have the following in your `etc/bluedata_infra.tfvars`:

```
mapr_cluster_1_count         = 3
mapr_cluster_1_name          = "dc1.enterprise.org"
mapr_cluster_2_count         = 3
mapr_cluster_2_name          = "edge1.enterprise.org"
```

**IMPORTANT**: Ensure the mapr hosts have nvme drives.

 - run `git pull` to get the latest code
 - run `./bin/terraform_apply.sh` to create the AWS infrastructure for MAPR

### Install and Setup MAPR

```
./scripts/end_user_scripts/standalone_mapr/setup_mapr.sh
```

### Register License

- This requires an account on https://mapr.com/user - create one if you don't have one alread.
```
./scripts/end_user_scripts/standalone_mapr/register_license.sh
```

### Setup Edge Demo

```
./scripts/end_user_scripts/standalone_mapr/setup_edge_demo.sh
```

## Run the demo

### Run Dashboards


- Open a New terminal, then run

```
./bin/mapr_edge_demo_start.sh
```

### Open dashboards

```
./bin/mapr_edge_demo_urls.sh
```

### Setup Mirroring, Replication, etc

- Open a New terminal, then run

```
./bin/mapr_edge_demo_poststartup.sh
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
./bin/mapr_edge_demo_watch_mirror.sh
```
