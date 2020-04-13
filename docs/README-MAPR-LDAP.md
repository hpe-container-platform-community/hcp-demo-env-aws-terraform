This document is a work-in-progress. Please raise an issue if you encounter an issue or any confusion.

----

## Setup MAPR with LDAP autentication for remote client access and DataTap

See here for more info: http://docs.bluedata.com/50_mapr-control-system

### Pre-requisites

These instructions assume you have deployed the AD server by setting `ad_server_enabled=true` in your `bluedata_infra.tfvars` file.  You will need to run `terraform apply ...` after making the update.  

After `terraform apply`, run `terraform output ad_server_private_ip` to get the AD server IP address.

Please read the scripts to understand what they are doing - they aren't too complicated!

### Configure the epic-mapr docker container for LDAP authentication

From your client machine where the github project is checked out, run:

```
./scripts/end_user_scripts/mapr_ldap/1_setup_epic_mapr_sssd.sh
```

### Configure the RDP jump host server for LDAP authentication.

From your client machine where the github project is checked out, run:

```
./scripts/end_user_scripts/mapr_ldap/2_setup_ubuntu_mapr_sssd_and_mapr_client.sh
```

### Setup Datatap on HCP in the EPIC Demo Tenant

```
./scripts/end_user_scripts/mapr_ldap/3_setup_datatap.sh
```

Run this script every time you add a new worker host to your HCP cluster.

### Test Datatap on an EPIC Spark 2.4 Cluster 

On RDP host add a data set:

```
sudo su - ad_admin1
wget https://raw.githubusercontent.com/fivethirtyeight/data/master/airline-safety/airline-safety.csv
mv airline-safety.csv /mapr/hcp.mapr.cluster/tmp/
```

Ensure you have setup HCP and EPIC Demo Tenant with LDAP - [./README-AD.md](./README-AD.md)

Create a spark 2.4 cluster with 1 controller and 1 jupyterhub (both nodes can use the small flavor).

Login to jupyterhub (ad_admin1/pass123) and launch a python 3 Jupyter notebook (not Spark).

In the jupyter notebook, create a cell with the following contents:

```
! hadoop fs -cat dtap://MaprClus1/tmp/airline-safety.csv
```
 
Run this cell - you should see data from the airline-safety.csv file, e.g.

```
2020-04-13 13:30:45 WARN  NativeCodeLoader:62 - Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Xiamen Airlines,430462962,9,1,82,2,0,0,0,7,224,11,2,23ccidents_85_99,fatalities_85_99,incidents_00_14,fatal_accidents_00_14,fatalities_00_14
```

### Create a Shared Volume in MAPR

TODO ... coming soon
