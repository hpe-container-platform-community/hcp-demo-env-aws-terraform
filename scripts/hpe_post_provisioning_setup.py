#!/usr/bin/env python3

from hpecp import ContainerPlatformClient
import json,sys,subprocess
import os

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

################################
# Retrieve the list of Tenants #
################################

for tenant in client.epic_tenant.list():
    # shorten name and description fields if they are too long
    name = (tenant.name[0:18] + '..') if len(tenant.name) > 20 else tenant.name
    description = (tenant.description[0:38] + '..') if len(tenant.description) > 40 else tenant.description
    
    print( "{:>2} | {:>20} | {:>40} | {:>10}".format( tenant.tenant_id, name, description, tenant.status) )

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

# Set up only the AD Admins Group
client.epic_tenant.auth_setup(
        tenant_id = 2,
        data =  {"external_user_groups":[{ 
            "role":"/api/v1/role/2", # 2 = Admins
            "group":"CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com"
            }]}
    )

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


################
# Add K8S host # 
################

worker_0_private_ip  = j["workers_private_ip"]["value"][0][0]

with open('/certs/controller.prv_key', 'r') as f:
    prvkey = f.read()

response = client.worker.add_k8shost(
            data ={
                "ipaddr":worker_0_private_ip,
                "credentials":{
                    "type":"ssh_key_access",
                    "ssh_key_data":prvkey
                },
                "tags":[]
            }
    )

print(response)
