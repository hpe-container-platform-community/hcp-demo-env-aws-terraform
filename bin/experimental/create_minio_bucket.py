#!/usr/bin/env python3

from minio import Minio
from minio.error import S3Error
import urllib3

def main():
 
    httpClient = urllib3.PoolManager(cert_reqs = 'CERT_NONE')
    
    # Create a client with the MinIO server playground, its access key
    # and secret key.
    
    GATEWAY = os.env("GATW_PUB_IP")
    
    client = Minio(
        "10.109.86.212:30270",
        access_key="admin",
        secret_key="admin123",
        secure=True,
        http_client = httpClient
    )

    # Make 'asiatrip' bucket if not exist.
    found = client.bucket_exists("mlflow")
    if not found:
        client.make_bucket("mlflow")
    else:
        print("Bucket 'mlflow' already exists")

if __name__ == "__main__":
    try:
        main()
    except S3Error as exc:
        print("error occurred.", exc)