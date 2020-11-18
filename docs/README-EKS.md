### EKS Cluster Import

Functionality has been added to the terraform scripts to easily create an EKS cluster that can be imported in HPE Container Platform.

Ensure you have the latest terraform scripts:

```
git pull
```

### Configure etc/bluedata_infra.tfvars

Edit `etc/bluedata_infra.tfvars`.

```
create_eks_cluster              = false
eks_instance_type               = "t2.micro"    # You can change this, e.g. "t3.2xlarge"
eks_scaling_config_desired_size = 1             # must be >= 1
eks_scaling_config_max_size     = 1             # must be >= 1
eks_scaling_config_min_size     = 1             # must be >= 1
eks_subnet2_cidr_block          = "10.1.2.0/24" # you shouldn't need to change this
eks_subnet3_cidr_block          = "10.1.3.0/24" # you shouldn't need to change this
eks_subnet2_az_suffix           = "b"           # you shouldn't need to change this
eks_subnet3_az_suffix           = "c"           # you shouldn't need to change this
```

After editing `etc/bluedata_infra.tfvars`, run:

```
./bin/terraform_apply.sh
```

The EKS cluster can take 15 or more minutes to come online.

### Retrieve EKS cluster details

After terraform has finished applying the changes, you can run the following script to retrieve the cluster endpoints:

```
./scripts/eks_setup.sh
```

You can then navigate to the HPE CP user interface screen for K8S Clusters and click **Import Cluster**.  Populate the form with the output from the above script.

E.g.

```
Pod DNS Domain: cluster.local
EKS SERVER: https://xxxxx.eks.amazonaws.com
EKS CA CERT:
xxxxxx=
EKS TOKEN:
xxxxxx=
```

IMPORTANT: You need to be connected to the vpn for the above script to work.

### Resizing the EKS cluster

You can change the following parameters to resize the EKS cluster:

```
eks_instance_type               = "t2.micro"    # You can change this, e.g. "t3.2xlarge"
eks_scaling_config_desired_size = 1             # must be >= 1
eks_scaling_config_max_size     = 1             # must be >= 1
eks_scaling_config_min_size     = 1             # must be >= 1
```

After making changes, be sure to run `./bin/terraform_apply.sh` to apply the changes.

### Stopping the EKS instance

You can stop the EKS instance using the AWS EC2 Console.  

Before stopping instances, be sure to set the desired_size, max_size and min_size to 1 and apply the changes.  
If you don't do this, autoscaling will replace stopped instances with new ones!!

The EKS worker EC2 instances will be tagged with the `Name=${project_id}-eks-instance`.

