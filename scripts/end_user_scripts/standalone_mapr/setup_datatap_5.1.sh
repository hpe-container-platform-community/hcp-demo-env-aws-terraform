#!/usr/bin/env bash

set -e
set -o pipefail

if [[ -z $1 ]]; then
  echo Usage: $0 TENANT_ID [ DEFAULT_MAPR_VMNT ]
  echo Where: TENANT_ID = /api/v1/tenant/[0-9]*
  exit 1
fi

set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

TENANT_ID=$(basename $1)

DEFAULT_MAPR_VMNT=/
MAPR_VMNT=${2:-$DEFAULT_MAPR_VMNT} 

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../variables.sh"
source "$SCRIPT_DIR/functions.sh"

if [[ "$AD_SERVER_ENABLED" == False ]]; then
   echo "Skipping script '$0' because AD Server is not enabled"
   exit
fi

print_term_width '='
echo "Setting up DataTap to standalone MAPR"
print_term_width '='


MAPR_CLUSTER1_HOST=${MAPR_CLUSTER1_HOSTS_PRV_IPS[0]} # From variables.sh
MAPR_USER=ad_admin1
MAPR_TCKT=ad_admin1_impersonation_ticket
MAPR_TCKT_PATH=/tmp/${MAPR_TCKT}
MAPR_VOL=demo_tenant_admins
MAPR_CLUSTER_NAME=${MAPR_CLUSTER1_NAME}
MAPR_DTAP_NAME=ext-mapr

TENANT_KEYTAB_DIR=/srv/bluedata/keytab/${TENANT_ID}/
TENANT_KEYTAB_TCKT_FILE=${TENANT_KEYTAB_DIR}${MAPR_TCKT}

echo MAPR_CLUSTER1_HOST=${MAPR_CLUSTER1_HOST}
echo MAPR_USER=${MAPR_USER}
echo MAPR_TCKT=${MAPR_TCKT}
echo MAPR_TCKT_PATH=${MAPR_TCKT_PATH}
echo MAPR_VOL=${MAPR_VOL}
echo MAPR_VMNT=${MAPR_VMNT}
echo MAPR_CLUSTER_NAME=${MAPR_CLUSTER_NAME}
echo MAPR_DTAP_NAME=${MAPR_DTAP_NAME}
echo TENANT_KEYTAB_DIR=${TENANT_KEYTAB_DIR}
echo TENANT_KEYTAB_TCKT_FILE=${TENANT_KEYTAB_TCKT_FILE}
echo AD_ADMIN_GROUP=${AD_ADMIN_GROUP}
echo AD_MEMBER_GROUP=${AD_MEMBER_GROUP}

print_term_width '-'
echo "Setting up mapr acls and volumes"
print_term_width '-'

# create mapr volumes
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_CLUSTER1_HOSTS_PUB_IPS[0]} << ENDSSH
	export MAPR_TICKETFILE_LOCATION=/home/ubuntu/mapr_user_ticket
	echo mapr | maprlogin password -user mapr -cluster ${MAPR_CLUSTER_NAME} -out \${MAPR_TICKETFILE_LOCATION}

	# Add Active Directory user and group
	maprcli acl edit \
			-cluster ${MAPR_CLUSTER_NAME} -type cluster -user ad_admin1:fc

	maprcli acl edit \
			-cluster ${MAPR_CLUSTER_NAME} -type cluster -group ${AD_ADMIN_GROUP}:login,cv

	# maprcli acl show -type cluster
	
	# # note: ignore errors so script can be idempotent
	# maprcli volume create \
	# 		-name ${MAPR_VOL} -path ${MAPR_VMNT} || echo "^ Ignoring error ^"

	# maprcli acl set \
	# 		-type volume -name ${MAPR_VOL} -user ad_admin1:fc

	# #hadoop fs -chgrp ${AD_ADMIN_GROUP} /demo_tenant_admins

	# hadoop fs -chmod 777 /demo_tenant_admins
ENDSSH

print_term_width '-'
echo "Creating mapr ticket for ${MAPR_USER}"
print_term_width '-'

# create a mapr ticket for use with datatap
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_CLUSTER1_HOSTS_PUB_IPS[0]} << ENDSSH
	echo pass123 | maprlogin password -user ${MAPR_USER} -cluster ${MAPR_CLUSTER_NAME}
	maprlogin generateticket -type servicewithimpersonation -user ${MAPR_USER} -out maprfuseticket
ENDSSH
MAPRFUSETICKET=$(ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_CLUSTER1_HOSTS_PUB_IPS[0]} cat maprfuseticket)
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


	rm -rf ~/hpecp_docker
	mkdir ~/hpecp_docker
	cd ~/hpecp_docker
	
	cat > Dockerfile <<-CAT_EOF
		FROM python:3
		WORKDIR /usr/src/app
		COPY requirements.txt ./
		COPY .hpecp.conf /root/.hpecp.conf
		COPY tenant_ad_auth.json /root/tenant_ad_auth.json
		COPY datatap.json /root/datatap.json
		RUN pip install --no-cache-dir -r requirements.txt
		COPY . .	
	CAT_EOF

	echo hpecp > requirements.txt
	
	cat > .hpecp.conf <<-CAT_EOF
		[default]
		api_host = ${CTRL_PRV_IP}
		api_port = 8080
		use_ssl = ${INSTALL_WITH_SSL}
		verify_ssl = False
		warn_ssl = False
		username = admin
		password = admin123

		[tenant${TENANT_ID}]
		tenant   = /api/v1/tenant/${TENANT_ID}
		username = ad_admin1
		password = pass123
	CAT_EOF
	
	# setup AD user for tenant Administrator
	# NOTE:
	#  - /api/v1/role/2 = Admins
	#  - /api/v1/role/3 = Members
	cat > tenant_ad_auth.json<<-JSON_EOF
	{
		"external_user_groups": [
		    {
			"role": "/api/v1/role/2",
			"group":"CN=${AD_ADMIN_GROUP},CN=Users,DC=samdom,DC=example,DC=com"
		    },
		    {
			"role": "/api/v1/role/3",
			"group": "CN=${AD_MEMBER_GROUP},CN=Users,DC=samdom,DC=example,DC=com"
		    }
		]
	}
	JSON_EOF
	
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
		      "${MAPR_CLUSTER1_HOSTS_PRV_IPS[0]}", "${MAPR_CLUSTER1_HOSTS_PRV_IPS[1]}"
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
	
	docker build -t my-python-app .
	cd ~
		
	# test connectivity to HPE CP with the CLI
	docker run -e LOG_LEVEL=DEBUG my-python-app hpecp license platform-id

	docker run -e LOG_LEVEL=DEBUG my-python-app hpecp httpclient put /api/v1/tenant/${TENANT_ID}?external_user_groups --json-file /root/tenant_ad_auth.json

	# The datatap needs to be created as a tenant administrator, not as global admin, hence the profile
	docker run -e LOG_LEVEL=DEBUG -e PROFILE=tenant${TENANT_ID} my-python-app hpecp httpclient post /api/v1/dataconn --json-file /root/datatap.json
SSH_EOF

print_term_width '-'
