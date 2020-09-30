### Overview


Download jq transformation script:

```console
curl -sLO https://raw.githubusercontent.com/antonbabenko/terraform-cost-estimation/master/terraform.jq
```

Extract current configuration and send to https://cost.modules.tf/ for an estimate

```console
terraform state pull | jq -cf terraform.jq | curl -s -X POST -H "Content-Type: application/json" -d @- https://cost.modules.tf/
```

Outputs something like:

```json
{"hourly": 11.27, "monthly": 8115.26}
```

Btw my environment currently looks like this for the above cost estimation:

```console
$ ./generated/get_private_endpoints.sh
-------------  ----------------  --------------------------------------------------------
         NAME                IP                                                       DNS
-------------  ----------------  --------------------------------------------------------
   RDP Server        10.1.0.113                                                        NA
   Controller        10.1.0.181                  ip-10-1-0-181.eu-west-3.compute.internal
      Gateway         10.1.0.39                   ip-10-1-0-39.eu-west-3.compute.internal
           AD        10.1.0.214                                                        NA
    Worker  0        10.1.0.220                  ip-10-1-0-220.eu-west-3.compute.internal
    Worker  1         10.1.0.80                   ip-10-1-0-80.eu-west-3.compute.internal
    Worker  2        10.1.0.145                  ip-10-1-0-145.eu-west-3.compute.internal
    Worker  3         10.1.0.36                   ip-10-1-0-36.eu-west-3.compute.internal
MAPR CLS 1  0         10.1.0.67                   ip-10-1-0-67.eu-west-3.compute.internal
MAPR CLS 1  1         10.1.0.87                   ip-10-1-0-87.eu-west-3.compute.internal
MAPR CLS 1  2        10.1.0.126                  ip-10-1-0-126.eu-west-3.compute.internal
-------------  ----------------  --------------------------------------------------------
```

**NOTE:**. 

This only estimates:

 - aws_instance
 - aws_ebs_volume
 - aws_ebs_snapshot
 - aws_ebs_snapshot_copy
 - aws_nat_gateway

### References

- https://github.com/antonbabenko/terraform-cost-estimation

