If you need to remove a host but don't want to destroy everything (i.e. with terraform destroy):
 
```
$ terraform state list
...
module.controller.aws_instance.controller
...
```

then

```
$ terraform taint module.controller.aws_instance.controller
$ ./bin/terraform_apply.sh # or ./bin/terraform_apply_accept.sh
```
