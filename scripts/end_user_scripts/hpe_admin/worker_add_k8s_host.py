#!/usr/bin/env python3

from hpecp import ContainerPlatformClient
import json,sys,subprocess
import os
import argparse

parser = argparse.ArgumentParser(description='Add K8S Worker Host.')
parser.add_argument('ip_address', metavar='ip_address', type=str, nargs=1,
                   help='worker host ip address')

args = parser.parse_args()
worker_host_ip = args.ip_address[0]

print("args.ip_address: {}".format(args.ip_address))


os.environ["LOG_LEVEL"] = "DEBUG"

json_file = './generated/output.json'
try:
    with open(json_file) as f:
        j = json.load(f)
except FileNotFoundError:
    print("ERROR: File not found: {}".format(json_file))
    sys.exit(1)
except:
    print(80 * "*")
    print("ERROR: Can't parse: '{}'".format(json_file))
    print(80 * "*")
    sys.exit(1)

controller_public_ip  = j["controller_public_ip"]["value"]
controller_ssh_key    = j["ssh_prv_key_path"]["value"]

client = ContainerPlatformClient(username='admin', 
                                password='admin123', 
                                api_host=controller_public_ip, 
                                api_port=8080,
                                use_ssl=True,
                                verify_ssl=False
                                )

client.create_session()

with open(controller_ssh_key, 'r') as f:
    prvkey = f.read()

client.worker.add_k8shost(
            data ={
                "ipaddr":worker_host_ip,
                "credentials":{
                    "type":"ssh_key_access",
                    "ssh_key_data":prvkey
                },
                "tags":[]
            }
    )
