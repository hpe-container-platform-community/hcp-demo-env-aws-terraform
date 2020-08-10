#!/usr/bin/env python3

import os
import sys
import json
from argparse import ArgumentParser
from urllib.parse import urlencode, quote_plus

import boto3

with open('credentials.json', 'r') as fd:
    credentials = json.loads(fd.read())

def main():

    parser = ArgumentParser(description='Creates a Presigned URL')
    parser.add_argument('--bucket-name',
                        dest='bucket_name',
                        action='store',
                        required=True,
                        help='the name of the bucket to upload to')
    parser.add_argument('--object-name',
                        dest='object_name',
                        action='store',
                        required=True,
                        help='the name of the object to upload')
    args = parser.parse_args()

    s3 = boto3.client('s3',
        aws_access_key_id=credentials.get('access_key'),
        aws_secret_access_key=credentials.get('secret_key'),
    )

    response = s3.generate_presigned_url(
        ClientMethod='put_object',
        Params={'Bucket': args.bucket_name, 'Key': args.object_name},
        ExpiresIn=3600,
    )

    print(f"curl -i --request PUT --upload-file {args.object_name} '{response}'")

if __name__ == '__main__':
    main()
