#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../variables.sh"




for HOST in $CTRL_PUB_IP ${WRKR_PUB_IPS[@]}; 
do
	echo HOST=$HOST
	ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" centos@$HOST <<-SSH_EOF
		set -xeu

		sudo bash -c "cat > /etc/yum.repos.d/maprtech.repo <<-EOF
		[maprtech]
		name=MapR Technologies
		baseurl=http://package.mapr.com/releases/v5.1.0/redhat/
		enabled=1
		gpgcheck=0
		protect=1

		[maprecosystem]
		name=MapR Technologies
		baseurl=http://package.mapr.com/releases/ecosystem-5.x/redhat
		enabled=1
		gpgcheck=0
		protect=1
		EOF"

		#wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
		#sudo rpm -Uvh epel-release-6*.rpm

		sudo rpm --import http://package.mapr.com/releases/pub/maprgpg.key
		sudo yum install -y mapr-client.x86_64 java-1.7.0-openjdk.x86_64
		[[ -d /mapr ]] || sudo mkdir /mapr
		export LD_LIBRARY_PATH=/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.131.x86_64/jre/lib/amd64/server/:/opt/mapr/lib
		docker cp epic-mapr:/opt/mapr/conf/ssl_truststore .
		sudo cp /home/centos/ssl_truststore  /opt/mapr/conf/
		sudo chown root:root /opt/mapr/conf/ssl_truststore

		sudo /opt/mapr/server/configure.sh -N hcp.mapr.cluster -c -secure -C $CTRL_PRV_IP -HS 
		echo pass123 | maprlogin password -cluster hcp.mapr.cluster -user ad_admin1
		maprlogin generateticket -type service -out /tmp/longlived_ticket -duration 30:0:0 -renewal 90:0:0

		sudo yum install -y mapr-posix-client-*
		sudo service mapr-posix-client-basic start

		ls /mapr/
	SSH_EOF
done

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} <<-SSH_EOF
	wget -c https://bluedata-releases.s3.amazonaws.com/dtap-mapr/create_dataconn.py
	wget -c https://bluedata-releases.s3.amazonaws.com/dtap-mapr/settings.py
	wget -c https://bluedata-releases.s3.amazonaws.com/dtap-mapr/session.py
SSH_EOF