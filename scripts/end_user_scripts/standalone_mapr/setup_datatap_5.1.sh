#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../variables.sh"
source "$SCRIPT_DIR/functions.sh"

print_term_width '='
echo "Setting up DataTap to standalone MAPR"
print_term_width '='


MAPR_HOST=${MAPR_HOSTS_PRV_IPS[0]} # From variables.sh
MAPR_USER=ad_admin1
MAPR_TCKT=ad_admin1_impersonation_ticket
MAPR_TCKT_PATH=/tmp/${MAPR_TCKT}
MAPR_VOL=demo_tenant_admins
MAPR_VMNT=/demo_tenant_admins
MAPR_CLUSTER_NAME=demo.mapr.com
MAPR_DTAP_NAME=ext-mapr
# 2 = EPIC Demo Tenant
TENANT_KEYTAB_DIR=/srv/bluedata/keytab/2/
TENANT_KEYTAB_TCKT_FILE=${TENANT_KEYTAB_DIR}${MAPR_TCKT}

echo MAPR_HOST=${MAPR_HOST}
echo MAPR_USER=${MAPR_USER}
echo MAPR_TCKT=${MAPR_TCKT}
echo MAPR_TCKT_PATH=${MAPR_TCKT_PATH}
echo MAPR_VOL=${MAPR_VOL}
echo MAPR_VMNT=${MAPR_VMNT}
echo MAPR_CLUSTER_NAME=${MAPR_CLUSTER_NAME}
echo MAPR_DTAP_NAME=${MAPR_DTAP_NAME}
echo TENANT_KEYTAB_DIR=${TENANT_KEYTAB_DIR}
echo TENANT_KEYTAB_TCKT_FILE=${TENANT_KEYTAB_TCKT_FILE}

print_term_width '-'
echo "Setting up mapr acls and volumes"
print_term_width '-'

# create mapr volumes
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_HOSTS_PUB_IPS[0]} << ENDSSH
	export MAPR_TICKETFILE_LOCATION=/home/ubuntu/mapr_user_ticket
	echo mapr | maprlogin password -user mapr -cluster ${MAPR_CLUSTER_NAME} -out \${MAPR_TICKETFILE_LOCATION}

	# Add Active Directory user and group
	maprcli acl edit \
			-cluster ${MAPR_CLUSTER_NAME} -type cluster -user ad_admin1:fc

	maprcli acl edit \
			-cluster ${MAPR_CLUSTER_NAME} -type cluster -group DemoTenantAdmins:login,cv

	maprcli acl show -type cluster
	
	# note: ignore errors so script can be idempotent
	maprcli volume create \
			-name ${MAPR_VOL} -path ${MAPR_VMNT} || echo "^ Ignoring error ^"

	maprcli acl set \
			-type volume -name ${MAPR_VOL} -user ad_admin1:fc

	#hadoop fs -chgrp DemoTenantAdmins /demo_tenant_admins

	hadoop fs -chmod 777 /demo_tenant_admins
ENDSSH

print_term_width '-'
echo "Creating mapr ticket for ${MAPR_USER}"
print_term_width '-'

# create a mapr ticket for use with datatap
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_HOSTS_PUB_IPS[0]} << ENDSSH
	echo pass123 | maprlogin password -user ${MAPR_USER} -cluster ${MAPR_CLUSTER_NAME}
	maprlogin generateticket -type servicewithimpersonation -user ${MAPR_USER} -out maprfuseticket
ENDSSH
MAPRFUSETICKET=$(ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_HOSTS_PUB_IPS[0]} cat maprfuseticket)
# echo MAPRFUSETICKET:${MAPRFUSETICKET}

print_term_width '-'
echo "Saving mapr ticket to EPIC controller to ${TENANT_KEYTAB_TCKT_FILE}"
print_term_width '-'


ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} <<-SSH_EOF
	set -eu

	# copy impresonation ticket to the tenant folder on the controller
	sudo echo $MAPRFUSETICKET > ${TENANT_KEYTAB_TCKT_FILE}
	sudo chown centos:apache ${TENANT_KEYTAB_TCKT_FILE}
	sudo chmod 660 ${TENANT_KEYTAB_TCKT_FILE}
	sudo ls -l ${TENANT_KEYTAB_TCKT_FILE}

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
	export LOG_LEVEL=INFO
		
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
		    "path_from_endpoint": "${MAPR_VMNT}"
		  },
		  "endpoint": {
		    "cluster_name": "${MAPR_CLUSTER_NAME}",
		    "ticket": "${MAPR_TCKT}",
		    "type": "mapr",
		    "secure": true,
		    "cldb": [
		      "${MAPR_HOSTS_PRV_IPS[0]}", "${MAPR_HOSTS_PRV_IPS[1]}"
		    ],
		    "ticket_type": "servicewithimpersonation",
		    "ticket_user": "${MAPR_USER}",
		    "mapr_tenant_volume": false,
		    "impersonation_enabled": true
		  },
		  "flags": {
		    "read_only": false
		  },
		  "label": {
		    "name": "${MAPR_DTAP_NAME}",
		    "description": "mapr standalone volume"
		  }
		}
	JSON_EOF
	cat datatap.json
	PROFILE=tenant2 hpecp httpclient post /api/v1/dataconn --json-file datatap.json
SSH_EOF

print_term_width '-'
