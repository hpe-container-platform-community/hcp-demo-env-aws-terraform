#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../variables.sh"

AD_PRIVATE_IP=$AD_PRV_IP
LDAP_BASE_DN="CN=Users,DC=samdom,DC=example,DC=com"
LDAP_BIND_DN="cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com" # the ad server in the demo environment has been created with this DN
LDAP_BIND_PASSWORD="5ambaPwd@"
LDAP_ACCESS_FILTER="CN=Users,CN=Builtin,DC=samdom,DC=example,DC=com"
DOMAIN="samdom.example.com"


[[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" ]] && \
	ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-SSH_EOF
	set -xeu
	
	# Install the auth packages by executing the following command 
	sudo apt-get -q update && sudo apt-get install -y pamtester sssd
	
	sudo bash -c "cat > /etc/sssd/sssd.conf <<-EOF
		[domain/${DOMAIN}]
		debug_level = 3
		autofs_provider = ldap
		cache_credentials = True
		id_provider = ldap
		auth_provider = ldap
		chpass_provider = ldap
		access_provider = ldap
		ldap_uri = ldap://${AD_PRIVATE_IP}:389
		ldap_search_base = ${LDAP_BASE_DN}
		ldap_id_use_start_tls = False
		ldap_tls_cacertdir = /etc/openldap/cacerts
		ldap_tls_reqcert = never
		ldap_user_member_of = memberOf
		ldap_access_order = filter
		ldap_access_filter = (|(memberOf=CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com)(memberOf=CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com))
		ldap_id_mapping = False
		ldap_schema = ad
		ldap_user_gid_number = gidNumber
		ldap_group_gid_number = gidNumber
		ldap_user_object_class = posixAccount
		ldap_idmap_range_size = 200000
		ldap_user_gecos = gecos
		fallback_homedir = /home/%u
		ldap_user_home_directory = homeDirectory
		default_shell = /bin/bash
		ldap_group_object_class = posixGroup
		ldap_user_uid_number = uidNumber
		ldap_referrals = False
		ldap_idmap_range_max = 2000200000
		ldap_idmap_range_min = 200000
		ldap_group_name = cn
		ldap_user_name = cn
		ldap_default_bind_dn = ${LDAP_BIND_DN}
		ldap_user_shell = loginShell
		ldap_default_authtok = ${LDAP_BIND_PASSWORD}
		ldap_user_fullname = cn
		
		[sssd]
		services = nss, pam, autofs
		domains = ${DOMAIN}
		
		[nss]
		
		homedir_substring = /home
		
		[pam]
		
		[sudo]
		
		[autofs]
		
		[ssh]
		
		[pac]
		
		[ifp]
		
		[secrets]
		
		[session_recording]
		
	EOF"
	
	sudo rm -f /var/log/sssd/*.log
	
	sudo chown root:root /etc/sssd/sssd.conf
	sudo chmod 600 /etc/sssd/sssd.conf
	sudo systemctl enable sssd
	sudo systemctl stop sssd
	sudo systemctl restart sssd
	
	if ! grep 'pam_mkhomedir.so' /etc/pam.d/common-session; then
		sudo sed -i '/^session\s*required\s*pam_unix.so\s*$/a session required    pam_mkhomedir.so skel=/etc/skel/ umask=0022' /etc/pam.d/common-session
	fi
	cat /etc/pam.d/common-session

	sudo pamtester login ad_user1 open_session
	sudo id ad_user1
	sudo getent passwd ad_user1
	sudo getent group DemoTenantUsers
	
	echo 'Done setting up SSSD.'
SSH_EOF

[[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" ]] && \
	ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-SSH_EOF
	set -xeu

	sudo bash -c "echo 'deb https://package.mapr.com/releases/v6.1.0/ubuntu binary trusty' > /etc/apt/sources.list.d/mapr.list"
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BFDDB60966B3F0D6
	sudo apt update
	sudo apt-get install -q -y mapr-posix-client-platinum openjdk-8-jdk
	sudo modprobe fuse

	# Create required mapr:mapr user/group
	sudo bash -c "getent group mapr || groupadd -g 5000 mapr"
	sudo bash -c "getent passwd mapr || useradd -u 5000 -s /bin/bash -d /home/mapr -g 5000 mapr"

	# Replace IP addresses with HCP controller private IP
	sudo /opt/mapr/server/configure.sh -N hcp.mapr.cluster -C ${CTRL_PRV_IP} -Z ${CTRL_PRV_IP} -c -secure

	# get the ssl_truststore from MapR container
	ssh -o StrictHostKeyChecking=no centos@${CTRL_PRV_IP} 'docker cp epic-mapr:/opt/mapr/conf/ssl_truststore .'

	# UNABLE TO PROCESS OTHER COMMANDS AFTER THE ABOVE STATEMENT, SO CLOSE THIS
	# SSH SESSION AND OPEN A NEW ONE
SSH_EOF

[[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" ]] && \
	ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-SSH_EOF
	set -xeu

	scp -o StrictHostKeyChecking=no centos@${CTRL_PRV_IP}:~/ssl_truststore .
	sudo mv /home/ubuntu/ssl_truststore /opt/mapr/conf/
	sudo chown root:root /opt/mapr/conf/ssl_truststore
SSH_EOF

[[ "$RDP_SERVER_ENABLED" == True && "$RDP_SERVER_OPERATING_SYSTEM" == "LINUX" ]] && \
	ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-SSH_EOF
	set -xeu

	sudo su - ad_admin1
	echo pass123 | maprlogin password -user ad_admin1 -cluster hcp.mapr.cluster
	maprlogin generateticket -type servicewithimpersonation -user ad_admin1 -out maprfuseticket
	exit # return to ubuntu/local user
	
	sudo cp /home/ad_admin1/maprfuseticket /opt/mapr/conf/
	sudo bash -c "sed -i 's@[#]fuse.ticketfile.location=.*@fuse.ticketfile.location=/opt/mapr/conf/longlived_ticket@' /opt/mapr/conf/fuse.conf"

	[[ -d /mapr ]] || sudo mkdir /mapr
	
	sudo systemctl enable mapr-posix-client-platinum
	sudo service mapr-posix-client-platinum start
	
	cat > restart_posix_client.sh <<-EOF
		#!/bin/bash
		sudo service mapr-posix-client-platinum restart
	EOF
	chmod +x restart_posix_client.sh

	echo "Sleeping for 30s waiting for mount to come online"
	sleep 30

	# Test
	sudo su - ad_admin1
	[[ -d /mapr/hcp.mapr.cluster/ ]] || { echo "Error: /mapr/hcp.mapr.cluster was not mounted. Aborting."; exit 1; }
	ls -l /mapr/hcp.mapr.cluster/ 

	# upload some data
	wget https://raw.githubusercontent.com/fivethirtyeight/data/master/airline-safety/airline-safety.csv
	sed -i -e "s/\r/\n/g" airline-safety.csv # convert line endings
	mv airline-safety.csv /mapr/hcp.mapr.cluster/tmp/
SSH_EOF

