#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

pip3 install --quiet --upgrade git+https://github.com/hpe-container-platform-community/hpecp-client@master

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

echo "Configuring AD authentication"
JSON_FILE=$(mktemp)
trap "{ rm -f $JSON_FILE; }" EXIT
cat >$JSON_FILE<<-EOF
{ 
    "external_identity_server":  {
        "bind_pwd":"5ambaPwd@",
        "user_attribute":"sAMAccountName",
        "bind_type":"search_bind",
        "bind_dn":"cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com",
        "host":"${AD_PRV_IP}",
        "security_protocol":"ldaps",
        "base_dn":"CN=Users,DC=samdom,DC=example,DC=com",
        "verify_peer": false,
        "type":"Active Directory",
        "port":636 
    }
}
EOF
hpecp httpclient post /api/v2/config/auth --json-file ${JSON_FILE}
