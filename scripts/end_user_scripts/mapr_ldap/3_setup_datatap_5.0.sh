#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../variables.sh"

# Setup steps taken from: http://docs.bluedata.com/40_using-a-datatap-to-connect-to-a-mapr-fs

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} <<-SSH_EOF
	set -eu

	# delete any previous files - start with a clean slate
	rm -f create_dataconn.py settings.py session.py
	
	wget -c https://bluedata-releases.s3.amazonaws.com/dtap-mapr/create_dataconn.py
	wget -c https://bluedata-releases.s3.amazonaws.com/dtap-mapr/settings.py
	wget -c https://bluedata-releases.s3.amazonaws.com/dtap-mapr/session.py

	sed -i 's#http://localhost:8080#https://127.0.0.1:8080#' settings.py
	sed -i 's/replace with your tenant name/Demo Tenant/' settings.py
	sed -i 's/replace with the tenant admin user name/admin/' settings.py
	sed -i 's/replace with the password of the tenant admin user/admin123/' settings.py
 
	sed -i 's#return requests.post(url, spec, headers=session_header)#return requests.post(url, spec, headers=session_header, verify="/home/centos/minica.pem")#' create_dataconn.py
	sed -i 's#(url, headers=headers, timeout=20)#(url, headers=headers, timeout=20, verify="/home/centos/minica.pem")#g' session.py
	sed -i 's#(url, data=data, headers=headers, timeout=20)#(url, data=data, headers=headers, timeout=20, verify="/home/centos/minica.pem")#g' session.py

	chmod +x create_dataconn.py
	./create_dataconn.py -n MaprClus1 -p /mapr/hcp.mapr.cluster/ -t file || echo "Unexpected Error"
SSH_EOF

for HOST in $CTRL_PUB_IP ${WRKR_PUB_IPS[@]}; 
do
	echo HOST=$HOST
	ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" centos@$HOST <<-SSH_EOF
		set -eu

		# if the host doesn't have bdconfig, it hasn't been added to HCP yet
		if command -v bdconfig >/dev/null 2>&1; then

			sudo bash -c "cat > /etc/yum.repos.d/maprtech.repo <<-EOF
			[maprtech]
			name=MapR Technologies
			baseurl=http://package.mapr.com/releases/v6.1.0/redhat/
			enabled=1
			gpgcheck=0
			protect=1
			EOF"

			[[ -d /mapr ]] || sudo mkdir /mapr

			# NOTE: The following two commands aren't requird on the AMI instances as epel release 7 is installed
			# wget http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
			# sudo rpm -Uvh epel-release-6*.rpm

			sudo rpm --import http://package.mapr.com/releases/pub/maprgpg.key
			sudo yum install -y mapr-client.x86_64 java-1.8.0-openjdk.x86_64

			JRE_LD_LIBRARY_PATH=\$(rpm -ql java-1.8.0-openjdk-headless | grep "jre/lib/amd64/server\$")
			echo \${JRE_LD_LIBRARY_PATH}
			export LD_LIBRARY_PATH=\${JRE_LD_LIBRARY_PATH}:/opt/mapr/lib
			docker cp epic-mapr:/opt/mapr/conf/ssl_truststore .
			sudo cp /home/centos/ssl_truststore  /opt/mapr/conf/
			sudo chown root:root /opt/mapr/conf/ssl_truststore

			sudo /opt/mapr/server/configure.sh -N hcp.mapr.cluster -c -secure -C $CTRL_PRV_IP -HS 
			echo pass123 | maprlogin password -cluster hcp.mapr.cluster -user ad_admin1
			maprlogin generateticket -user ad_admin1 -type service -out /tmp/longlived_ticket -duration 30:0:0 -renewal 90:0:0
			sudo mv /tmp/longlived_ticket /opt/mapr/conf/
			sudo chown root:root /opt/mapr/conf/longlived_ticket
			sudo chmod 700 /opt/mapr/conf/longlived_ticket

			sudo yum install -y mapr-posix-client-platinum
			sudo bash -c "sed -i '/^.*fuse.ticketfile.location=.*$/d' /opt/mapr/conf/fuse.conf" # Delete previous config entries before adding a new one
			sudo bash -c "echo 'fuse.ticketfile.location=/opt/mapr/conf/longlived_ticket' >> /opt/mapr/conf/fuse.conf"
			tail /opt/mapr/conf/fuse.conf

			sudo systemctl enable mapr-posix-client-platinum
			sudo systemctl start mapr-posix-client-platinum

			echo "Sleeping for 30s for mount to come online"
			sleep 30

			[[ -d /mapr/hcp.mapr.cluster/ ]] || { echo "Error: /mapr/hcp.mapr.cluster was not mounted. Aborting."; exit 1; }
			ls -l /mapr/hcp.mapr.cluster
		fi
	SSH_EOF
done
