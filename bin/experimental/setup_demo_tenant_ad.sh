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

# set the log level for the HPE CP CLI
export LOG_LEVEL=DEBUG

# test connectivity to HPE CP with the CLI
hpecp license platform-id

# setup AD user for tenant Administrator
# NOTE:
#  - /api/v1/role/2 = Admins
#  - /api/v1/role/3 = Members

hpecp httpclient put "/api/v1/tenant/2?external_user_groups" --json-file <(echo '
{
	"external_user_groups": [
	    {
		"role": "/api/v1/role/2",
		"group":"CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com"
	    },
	    {
		"role": "/api/v1/role/3",
		"group": "CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com"
	    }
	]
}')
