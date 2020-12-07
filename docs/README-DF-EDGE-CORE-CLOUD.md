### Data Fabric - Edge Core Cloud Demo


### Prerequisites

- You have the application code: `data-fabric-edge-core-cloud-master.zip`

### HQ Setup

#### MAPR Setup

- Ensure you have the following in your `etc/bluedata_infra.tfvars`:

```
mapr_cluster_1_count         = 3
mapr_cluster_1_name          = "dc1.enterprise.org"
```

- Run `./bin/terraform_apply.sh`
- Run `./scripts/mapr_install.sh 1`
- Run `./scripts/end_user_scripts/standalone_mapr/setup_ubuntu_mapr_sssd.sh 1`
- Run `/generated/ssh_mapr_cluster_1_host_0.sh "cat > data-fabric-edge-core-cloud-master.zip" < /Users/christophersnow/Downloads/data-fabric-edge-core-cloud-master.zip`

#### K8S DataTap Setup (optional)

- Retrieve the tenant ID
- Run `./scripts/end_user_scripts/standalone_mapr/setup_datatap_5.1.sh $TENANT_ID /`
