### External Mapr Cluster(s)

You can optionally create one or two MAPR clusters that are deployed "next" to the HPE Container Platform.

These external clusters operate completely independently of the HPE Container Platform - unlike the "Embedded" MAPR Cluster.

#### Specifying 

You can specify MAPR clusters in etc/bluedata_infr.tfvars.  

```
mapr_cluster_1_count = 0                     # How many hosts do you want for MAPR CLUSTER1? (0 or 3)
mapr_cluster_2_count = 0                     # How many hosts do you want for MAPR CLUSTER2? (0 or 3)
```

Remember to run `./bin/terraform_apply.sh` after making changes to `etc/bluedata_infra.tfvars`.

#### Installing

To install `mapr_cluster_1`, run the following:

CLUSTER_ID=1
./scripts/mapr_install.sh ${CLUSTER_ID}
./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh ${CLUSTER_ID}

To install `mapr_cluster_2`, run the following:

CLUSTER_ID=1
./scripts/mapr_install.sh ${CLUSTER_ID}
./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh ${CLUSTER_ID}

#### IP Addresses

You can retrieve the public ips with `./generated/get_public_endpoints.sh`, E.g.

```
$ ./generated/get_public_endpoints.sh
-------------  ----------------  --------------------------------------------------------  -----
         NAME                IP                                                       DNS   EIP?
-------------  ----------------  --------------------------------------------------------  -----
...
MAPR CLS 1  0           1.2.3.4               ec2-1.2.3.4.eu-west-3.compute.amazonaws.com     NA
MAPR CLS 1  1           1.2.3.5               ec2-1.2.3.5.eu-west-3.compute.amazonaws.com     NA
MAPR CLS 1  2           1.2.3.6               ec2-1.2.3.6.eu-west-3.compute.amazonaws.com     NA
-------------  ----------------  --------------------------------------------------------  -----
```

The output above is for an environment where only `mapr_cluster_1` has been enabled.

Likewise, you can retrieve private IPs with `./generated/get_private_endpoints.sh`

#### Mapr Control System

MCS can be accessed at:

- https://{{MAPR CLS 1}}:8443 
  - username/password = mapr/mapr
  - use either public or private ip address
- https://{{MAPR CLS 2}}:8443
  - username/password = mapr/mapr
  - use either public or private ip address

#### DataTap

You can run the following script to create a DataTap to the Mapr 1 cluster in the EPIC demo tenant:

./scripts/end_user_scripts/standalone_mapr/setup_datatap_5.1.sh





