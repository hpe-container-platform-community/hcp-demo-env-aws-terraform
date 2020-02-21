```
Error: Error revoking security group xxxx: InvalidPermission.NotFound: The specified rule does not exist in this security group.
	status code: 400, request id: xxxx



Error: Error Deleting Network Acl Rule: InvalidNetworkAclEntry.NotFound: no ingress entry with number 200 in network ACL xxxx
	status code: 400, request id: xxxx

```

This may be the terraform state out of sync. You can delete specific states with `terraform state rm ...`.

E.g.:

```
terraform state rm 'aws_security_group_rule.allow_ssh_from_world[0]'
```
