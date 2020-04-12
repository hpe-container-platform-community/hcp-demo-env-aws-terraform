### Add more worker nodes

Set the variable `worker_count=` in `etc/bluedata_infra.tfvars` to the desired number.

```
# check the changes that will be done in the output - don't forget to approve when prompted
./bin/terraform_apply.sh

# run a script to prepare the worker - follow the prompts and instructions.
./scripts/bluedata_prepare_worker.sh
```
