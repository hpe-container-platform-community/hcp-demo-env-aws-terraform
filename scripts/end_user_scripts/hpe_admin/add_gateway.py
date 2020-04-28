#!/usr/bin/env python3

from hpecp import ContainerPlatformClient
import json,sys,subprocess
import os

# Disable the SSL warnings - don't do this on productions!  
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

os.environ["LOG_LEVEL"] = "DEBUG"

try:
    with open('./generated/output.json') as f:
        j = json.load(f)
except: 
    print(80 * "*")
    print("ERROR: Can't parse: './generated/output.json'")
    print(80 * "*")
    sys.exit(1)

controller_public_ip  = j["controller_public_ip"]["value"]
ad_server_private_ip  = j["ad_server_private_ip"]["value"]


client = ContainerPlatformClient(username='admin', 
                                password='admin123', 
                                api_host=controller_public_ip, 
                                api_port=8080,
                                use_ssl=True,
                                verify_ssl=False)

client.create_session()

################
# Add Gateway  # 
################

gateway_host_ip = j["gateway_private_ip"]["value"]
gateway_host_dns = j["gateway_private_dns"]["value"]

with open('/certs/controller.prv_key', 'r') as f:
    prvkey = f.read()

response = client.worker.add_gateway(
            data ={
                "ip": gateway_host_ip,
                "credentials":{
                    "type":"ssh_key_access",
                    "ssh_key_data":prvkey
                },
                "tags":[],
                "proxy_nodes_hostname":gateway_host_dns,
                "purpose":"proxy"
            }
    )

print(response)
