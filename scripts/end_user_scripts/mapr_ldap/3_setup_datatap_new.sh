#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../variables.sh"

# Setup steps taken from: http://docs.bluedata.com/40_using-a-datatap-to-connect-to-a-mapr-fs

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} <<-SSH_EOF
	set -xeu

	MAPR_USER=ad_admin1
	MAPR_TCKT=/tmp/ad_admin1_impersonation_ticket
	MAPR_VMNT=/global/global1

	# 2 = EPIC Demo Tenant
	TENANT_KEYTAB_DIR=/srv/bluedata/keytab/2/


	CONTAINER_ID=\$(docker ps | grep "epic-mapr" | cut -d " " -f1)

	bdmapr maprlogin generateticket -type servicewithimpersonation -user \${MAPR_USER} -out \${MAPR_TCKT}
	sudo docker cp \${CONTAINER_ID}:\${MAPR_TCKT} \${TENANT_KEYTAB_DIR}
	sudo chown centos:apache \${TENANT_KEYTAB_DIR}/\${MAPR_USER}_impersonation_ticket
	sudo chmod 660 \${TENANT_KEYTAB_DIR}/\${MAPR_USER}_impersonation_ticket

	docker exec -i \$CONTAINER_ID bash <<-DOCKER_EOF
		[[ -d /mapr/mnt/hcp.mapr.cluster/global ]] || mkdir /mapr/mnt/hcp.mapr.cluster/global
		chown -R mapr:mapr /mapr/mnt/hcp.mapr.cluster/global
		chmod -R 777 /mapr/mnt/hcp.mapr.cluster/global
	DOCKER_EOF

	bdmapr maprcli volume create -name global -path \${MAPR_VMNT} || true # ignore error
	bdmapr maprcli acl set -type volume -name global -user ad_admin1:fc || true # ignore error

	docker run -i --rm ubuntu:18.04 /bin/bash -s <<DOCK_EOF 
		set -xeu
		apt-get update 
		apt-get install -y python3-pip git
		pip3 install --quiet --upgrade git+https://github.com/hpe-container-platform-community/hpecp-client@master
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

		export LOG_LEVEL=DEBUG
		hpecp license platform-id

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
		hpecp httpclient post /api/v1/dataconn --json-file datatap.json
	DOCK_EOF
SSH_EOF
