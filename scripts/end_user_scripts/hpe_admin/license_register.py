#!/usr/bin/env python3

from hpecp import ContainerPlatformClient
import json,sys,subprocess
import os

# Disable the SSL warnings - don't do this on productions!  
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

os.environ["LOG_LEVEL"] = "INFO"

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

print("*" * 80)
print( "Current License:\n" + str(client.license.get_license()) )
print("*" * 80)
print( "Platform ID: " + client.license.get_platform_id() )
print("*" * 80)
lic = input("Paste License Text: ")

with open('./generated/LICENSE', 'w') as out_file:
     out_file.write(lic)

import subprocess
subprocess.run(["scp", "-i", "./generated/controller.prv_key", "./generated/LICENSE", "centos@{}:/srv/bluedata/license/LICENSE".format(controller_public_ip)])

client.license.register_license("/srv/bluedata/license/LICENSE")

print("*" * 80)
print( "Current License:\n" + str(client.license.get_license()) )
print("*" * 80)