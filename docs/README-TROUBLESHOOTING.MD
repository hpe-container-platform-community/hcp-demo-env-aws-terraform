```
Error: Error revoking security group xxxx: InvalidPermission.NotFound: The specified rule does not exist in this security group.
	status code: 400, request id: xxxx



Error: Error Deleting Network Acl Rule: InvalidNetworkAclEntry.NotFound: no ingress entry with number 200 in network ACL xxxx
	status code: 400, request id: xxxx

```

This can usually be fixed by running `terraform apply ...` for a second time.