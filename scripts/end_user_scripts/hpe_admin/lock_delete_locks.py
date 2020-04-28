#!/usr/bin/env python3

from hpecp import ContainerPlatformClient
import json,sys,subprocess
import os

# Disable the SSL warnings - don't do this on productions!  
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

#os.environ["LOG_LEVEL"] = "DEBUG"


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

client = ContainerPlatformClient(username='admin', 
                                password='admin123', 
                                api_host=controller_public_ip, 
                                api_port=8080,
                                use_ssl=True,
                                verify_ssl=False
                                )

client.create_session()

print("Deleting locks ...")
client.lock.delete_locks()

