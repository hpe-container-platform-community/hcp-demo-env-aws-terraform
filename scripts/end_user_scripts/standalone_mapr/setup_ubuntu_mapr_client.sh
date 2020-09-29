#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../variables.sh"

if [[ "$AD_SERVER_ENABLED" == False ]]; then
   echo "Skipping script '$0' because AD Server is not enabled"
   exit
fi

[[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" ]] && \
	ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-SSH_EOF
	set -eu

	MAPR_HOST_1=${MAPR_CLUSTER1_HOSTS_PRV_IPS[0]}
	MAPR_HOST_2=${MAPR_CLUSTER1_HOSTS_PRV_IPS[1]}

	# Replace IP addresses with HCP controller private IP
	sudo /opt/mapr/server/configure.sh -N demo1.mapr.com -C \${MAPR_HOST_1}:7222,\${MAPR_HOST_2}:7222 -c -secure

	rm -f ~ubuntu/external_mapr_cluster1_ssl_truststore
	scp -o StrictHostKeyChecking=no ubuntu@\${MAPR_HOST_1}:/opt/mapr/conf/ssl_truststore ~ubuntu/external_mapr_cluster1_ssl_truststore
	sudo /opt/mapr/server/manageSSLKeys.sh merge ~ubuntu/external_mapr_cluster1_ssl_truststore /opt/mapr/conf/ssl_truststore

	# UNABLE TO PROCESS OTHER COMMANDS AFTER THE ABOVE STATEMENT, 
	# SO CLOSE THIS SSH SESSION AND OPEN A NEW ONE
SSH_EOF

[[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" ]] && \
	ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-SSH_EOF
	set -eu

	sudo su - ad_admin1
	echo pass123 | maprlogin password -user ad_admin1 -cluster demo1.mapr.com
	maprlogin generateticket -type servicewithimpersonation -user ad_admin1 -out maprfuseticket
	exit # return to ubuntu/local user
	
	sudo cp /home/ad_admin1/maprfuseticket /opt/mapr/conf/
	sudo bash -c "sed -i 's@[#]fuse.ticketfile.location=.*@fuse.ticketfile.location=/opt/mapr/conf/longlived_ticket@' /opt/mapr/conf/fuse.conf"

	[[ -d /mapr ]] || sudo mkdir /mapr
	
	sudo systemctl enable mapr-posix-client-platinum
	sudo service mapr-posix-client-platinum start
	
	cat > ~ubuntu/restart_posix_client.sh <<-EOF
		#!/bin/bash
		sudo service mapr-posix-client-platinum restart
	EOF
	chmod +x restart_posix_client.sh

	./restart_posix_client.sh

	echo "Sleeping for 30s waiting for mount to come online"
	sleep 30

	# Test
	sudo su - ad_admin1
	[[ -d /mapr/demo1.mapr.com/ ]] || { echo "Error: /mapr/demo1.mapr.com was not mounted. Aborting."; exit 1; }
	ls -l /mapr/demo1.mapr.com/ 

	# upload some data
	wget https://raw.githubusercontent.com/fivethirtyeight/data/master/airline-safety/airline-safety.csv
	sed -i -e "s/\r/\n/g" airline-safety.csv # convert line endings
	mv airline-safety.csv /mapr/demo1.mapr.com/tmp/
SSH_EOF


exit 0
