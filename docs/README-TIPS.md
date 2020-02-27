If your epic download url is set for private access, you can create a presigned url using this:

```
EPIC_PRV_URL=s3://yourbucket/your.bin
echo MY_IP=$(curl -s http://ifconfig.me/ip) && \
terraform apply \
   -var-file=etc/bluedata_infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" \
   -var="epic_dl_url=$(aws s3 presign $EPIC_PRV_URL)" \
   -auto-approve=true && \
terraform output -json > generated/output.json && \
./scripts/bluedata_install.sh && \
./scripts/bluedata_config.sh 
```