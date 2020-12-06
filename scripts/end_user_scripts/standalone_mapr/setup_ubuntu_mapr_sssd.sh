#!/usr/bin/env bash

CLUSTER_ID=$1

if [[ -z $CLUSTER_ID ]]; then
    echo Usage: $0 CLUSTER-ID 
    echo        CLUSTER-ID can be 1 or 2
    exit 1
fi

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../variables.sh"
source "$SCRIPT_DIR/functions.sh"
source "$SCRIPT_DIR/verify_ad_server_config.sh"

if [[ "$AD_SERVER_ENABLED" == False ]]; then
   echo "Skipping script '$0' because AD Server is not enabled"
   exit
fi

AD_PRIVATE_IP=$AD_PRV_IP
LDAP_BASE_DN="CN=Users,DC=samdom,DC=example,DC=com"
LDAP_BIND_DN="cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com" # the ad server in the demo environment has been created with this DN
LDAP_BIND_PASSWORD="5ambaPwd@"
LDAP_ACCESS_FILTER="CN=Users,CN=Builtin,DC=samdom,DC=example,DC=com"
DOMAIN="samdom.example.com"

MAPR_CLUSTER_NAME=${MAPR_CLUSTER1_NAME}

if [[ ${CLUSTER_ID} == 1 ]]; then
    MAPR_CLUSTER_HOSTS_PRV_IPS=${MAPR_CLUSTER1_HOSTS_PRV_IPS[@]}
    MAPR_CLUSTER_HOSTS_PUB_IPS=${MAPR_CLUSTER1_HOSTS_PUB_IPS[@]}
else
    MAPR_CLUSTER_HOSTS_PRV_IPS=${MAPR_CLUSTER2_HOSTS_PRV_IPS[@]}
    MAPR_CLUSTER_HOSTS_PUB_IPS=${MAPR_CLUSTER2_HOSTS_PUB_IPS[@]}
fi


for MAPR_CLUSTER_HOST in ${MAPR_CLUSTER_HOSTS_PUB_IPS[@]}; do 

	print_term_width '='
	echo "Setting up SSSD on ${MAPR_CLUSTER_HOST}"
	print_term_width '='

	ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_CLUSTER_HOST} <<-SSH_EOF
	set -eu

	# don't display login banners
	sudo touch /etc/skel/.hushlogin
	sudo chmod -x /etc/update-motd.d/*
	
	# Install the auth packages by executing the following command 
	sudo apt-get -qq update > /dev/null  && sudo apt-get -qq install -y pamtester sssd > /dev/null
	
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
	# cat /etc/pam.d/common-session

	sudo pamtester login ad_user1 open_session
	sudo id ad_user1
	sudo getent passwd ad_user1
	sudo getent group DemoTenantUsers
	
	echo 'Done setting up SSSD.'
SSH_EOF

print_term_width '-'
ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_CLUSTER_HOST} <<-SSH_EOF

	set -eu

	echo mapr | maprlogin password -user mapr -cluster ${MAPR_CLUSTER_NAME}
 	# maprlogin generateticket -type servicewithimpersonation -user mapr -out maprfuseticket

	# Add Active Directory user and group
	maprcli acl edit \
			-cluster ${MAPR_CLUSTER_NAME} -type cluster -user ad_admin1:fc

	maprcli acl edit \
			-cluster ${MAPR_CLUSTER_NAME} -type cluster -group DemoTenantUsers:login,cv

	maprcli acl show -type cluster
SSH_EOF
done

print_term_width '-'
for MAPR_CLUSTER_HOST in ${MAPR_CLUSTER_HOSTS_PUB_IPS[@]}; do 
	# reboot - and if the reboot causes ssh to terminate with an error, ignore it
	echo "Rebooting Host:"
	ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_CLUSTER_HOST} "nohup sudo reboot </dev/null &" || true
done

print_term_width '-'
for MAPR_CLUSTER_HOST in ${MAPR_CLUSTER_HOSTS_PUB_IPS[@]}; do 
    echo "Waiting for host ${MAPR_CLUSTER_HOST} to accept ssh connections"
    while ! nc -w5 -z ${MAPR_CLUSTER_HOST} 22; do printf "." -n ; sleep 1; done;
    echo 'Host is back online.'
done

# Only verify connectivity to CLDB from the first host
for MAPR_CLUSTER_HOST in ${MAPR_CLUSTER_HOSTS_PUB_IPS[0]}; do 
	print_term_width '-'
	echo "Verifing CLDB is online:"
	print_term_width '-'
	for i in {1..1000}; do
		ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${MAPR_CLUSTER_HOST} \
			"echo mapr | maprlogin password -user mapr -cluster ${MAPR_CLUSTER_NAME}" \
			&& break # if maprlogin command was successful, exit loop

		sleep 1
	done
	echo "maprlogin was successful - CLDB is assumed to be online"
	print_term_width '-'
done
