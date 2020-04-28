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

###################################
# Configure global authentication #
###################################

client.config.auth(
            { "external_identity_server":  {
                "bind_pwd":"5ambaPwd@",
                "user_attribute":"sAMAccountName",
                "bind_type":"search_bind",
                "bind_dn":"cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com",
                "host":ad_server_private_ip,
                "security_protocol":"ldaps",
                "base_dn":"CN=Users,DC=samdom,DC=example,DC=com",
                "verify_peer": False,
                "type":"Active Directory",
                "port":636 }
            })

###################################
# Configure Tenant authentication #
###################################

# Set up both the AD Admins and Members
client.epic_tenant.auth_setup(
        tenant_id = 2,
        data =  {"external_user_groups":[
            {
                "role":"/api/v1/role/2", # 2 = Admins
                "group":"CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com"
            },
            { 
                "role":"/api/v1/role/3", # 3 = Members
                "group":"CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com"
            }]}
    )
