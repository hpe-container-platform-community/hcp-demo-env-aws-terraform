#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../variables.sh"

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} <<-SSH_EOF
	set -eu

	MAPR_USER=ad_admin1
	MAPR_TCKT=/tmp/ad_admin1_impersonation_ticket
	MAPR_VMNT=/global/global1

	# 2 = EPIC Demo Tenant
	TENANT_KEYTAB_DIR=/srv/bluedata/keytab/2/

	CONTAINER_ID=\$(docker ps | grep "epic-mapr" | cut -d " " -f1)

	# create an impresonation ticket and copy it to the tenant folder on the controller
	bdmapr maprlogin generateticket -type servicewithimpersonation -user \${MAPR_USER} -out \${MAPR_TCKT}
	sudo docker cp \${CONTAINER_ID}:\${MAPR_TCKT} \${TENANT_KEYTAB_DIR}
	sudo chown centos:apache \${TENANT_KEYTAB_DIR}/\${MAPR_USER}_impersonation_ticket
	sudo chmod 660 \${TENANT_KEYTAB_DIR}/\${MAPR_USER}_impersonation_ticket

	# create a mount point for the new volume
	docker exec -i \$CONTAINER_ID bash <<-DOCKER_EOF
		[[ -d /mapr/mnt/hcp.mapr.cluster/global ]] || mkdir /mapr/mnt/hcp.mapr.cluster/global
		chown -R mapr:mapr /mapr/mnt/hcp.mapr.cluster/global
		chmod -R 777 /mapr/mnt/hcp.mapr.cluster/global
	DOCKER_EOF

	# ignore errors so this script is idempotent
	bdmapr maprcli volume create -name global -path \${MAPR_VMNT} || true # ignore error
	bdmapr maprcli acl set -type volume -name global -user ad_admin1:fc || true # ignore error

	# create a mount point for the new volume
	docker exec -i \$CONTAINER_ID bash <<-DOCKER_EOF
		# upload some data
		wget https://raw.githubusercontent.com/fivethirtyeight/data/master/airline-safety/airline-safety.csv
		sed -i -e "s/\r/\n/g" airline-safety.csv # convert line endings
		mv airline-safety.csv /mapr/mnt/hcp.mapr.cluster/global/global1/
	DOCKER_EOF

	command -v hpecp >/dev/null 2>&1 || { 
		echo >&2 "Ensure you have run: bin/experimental/install_hpecp_cli.sh"
		exit 1; 
	}

	set +u
	pyenv activate my-3.6.10 # installed by bin/experimental/install_hpecp_cli.sh
	set -u	
		
	# First we need 'admin' to setup the Demo Tenant authentication AD groups
	cat > ~/.hpecp.conf <<-CAT_EOF
		[default]
		api_host = ${CTRL_PRV_IP}
		api_port = 8080
		use_ssl = ${INSTALL_WITH_SSL}
		verify_ssl = False
		warn_ssl = False
		username = admin
		password = admin123
	CAT_EOF

	# set the log level for the HPE CP CLI 
	export LOG_LEVEL=DEBUG
		
	# test connectivity to HPE CP with the CLI
	hpecp license platform-id

	# setup AD user for tenant Administrator
	# NOTE:
	#  - /api/v1/role/2 = Admins
	#  - /api/v1/role/3 = Members
	cat >tenant_ad_auth.json<<-JSON_EOF
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
	}
	JSON_EOF
	hpecp httpclient put /api/v1/tenant/2?external_user_groups --json-file tenant_ad_auth.json

	# The datatap needs to be created as a tenant administrator, not as global admin
	cat > ~/.hpecp.conf <<-CAT_EOF
		[default]
		api_host = ${CTRL_PRV_IP}
		api_port = 8080
		use_ssl = ${INSTALL_WITH_SSL}
		verify_ssl = False
		warn_ssl = False

		[tenant2]
		tenant   = /api/v1/tenant/2
		username = ad_admin1
		password = pass123
	CAT_EOF

	cat >datatap.json<<-JSON_EOF
		{
		  "bdfs_root": {
		    "path_from_endpoint": "\${MAPR_VMNT}"
		  },
		  "endpoint": {
		    "cluster_name": "hcp.mapr.cluster",
		    "ticket": "\${MAPR_USER}_impersonation_ticket",
		    "type": "mapr",
		    "secure": true,
		    "cldb": [
		      "${CTRL_PRV_IP}"
		    ],
		    "ticket_type": "servicewithimpersonation",
		    "ticket_user": "\${MAPR_USER}",
		    "mapr_tenant_volume": false,
		    "impersonation_enabled": true
		  },
		  "flags": {
		    "read_only": false
		  },
		  "label": {
		    "name": "globalshare",
		    "description": "mapr volume global share"
		  }
		}
	JSON_EOF
	PROFILE=tenant2 hpecp httpclient post /api/v1/dataconn --json-file datatap.json
SSH_EOF
