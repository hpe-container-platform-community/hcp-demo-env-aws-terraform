#!/usr/bin/env bash

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

export HOST=$1
echo HOST=$HOST

ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-SSH_EOF

    export PYTHONPATH=\$PYTHONPATH:~/.local/lib/python3.6/site-packages/
    export PYTHONWARNINGS="ignore:Unverified HTTPS request"
    
    pip3 install minio --user --quiet
    pip3 install requests --user --quiet

    python3 - <<PYTHON_EOF

from minio import Minio
from minio.error import S3Error
import urllib3
import sys

httpClient = urllib3.PoolManager(cert_reqs = 'CERT_NONE')

client = Minio(
    "$HOST",
    access_key="admin",
    secret_key="admin123",
    secure=True,
    http_client = httpClient
)

found = client.bucket_exists("mlflow")
if not found:
    client.make_bucket("mlflow")
    print("Created bucket 'mflow'")
else:
    print("Bucket 'mlflow' already exists")

PYTHON_EOF

SSH_EOF