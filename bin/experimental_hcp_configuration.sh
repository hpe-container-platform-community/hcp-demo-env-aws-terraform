#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

pip3 install --quiet --upgrade git+https://github.com/hpe-container-platform-community/hpecp-client@master

# Save the configuration file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"
cat >$HPECP_CONFIG_FILE<<EOF
[default]
api_host = ${CTRL_PUB_IP}
api_port = 8080
use_ssl = True
verify_ssl = False
warn_ssl = False
username = admin
password = admin123
EOF

echo "Checking for LICENSE locally"
# Register license so workers can be fully installed
if [[ ! -f generated/LICENSE ]]; then
    echo "ERROR: File './generated/LICENSE' not found - please add it - platform ID: $(hpecp license platform-id)"
    echo "       After adding the file, run this script again"
    exit 
fi

echo "Uploading LICENSE to Controller"
scp -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" ./generated/LICENSE centos@${CTRL_PUB_IP}:/srv/bluedata/license/LICENSE
hpecp license delete-all
hpecp license register /srv/bluedata/license/LICENSE
hpecp license list

echo "Deleting and creating lock"
hpecp lock delete-all
hpecp lock create "Install Gateway"

set -x

EXISTING_GATEWAY_IDS=$(hpecp gateway list --columns "['id']" --output text)
for GW in ${EXISTING_GATEWAY_IDS}; do
   hpecp gateway delete ${GW}
   hpecp gateway wait-for-state ${GW} --states "[]" --timeout-secs 1200
done

echo "Configuring the Gateway"
GATEWAY_ID=$(hpecp gateway create-with-ssh-key $GATW_PRV_IP $GATW_PRV_DNS --ssh-key-file generated/controller.prv_key)

echo "Waiting for gateway to have state 'installed'"
hpecp gateway wait-for-state ${GATEWAY_ID} --states "['installed']" --timeout-secs 1200
hpecp gateway list
hpecp lock delete-all

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

echo "Adding workers"
for WRKR in ${WRKR_PRV_IPS[@]}; do
    echo "   worker $WRKR"
    ./scripts/end_user_scripts/hpe_admin/worker_add_k8s_host.py ${WRKR}
done


# Finish worker install
./scripts/end_user_scripts/hpe_admin/worker_set_storage_k8s_host.py
