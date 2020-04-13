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

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -tt -T centos@${CTRL_PUB_IP} <<-SSH_EOF
	set -xeu
	
	CONTAINER_ID=\$(docker ps | grep "epic-mapr" | cut -d " " -f1)
	docker exec -i \$CONTAINER_ID bash <<-DOCKER_EOF
		set -xeu
	
		# Install the auth packages by executing the following command - TODO: really disable pgpcheck??
		yum install -y authconfig openldap openldap-clients pamtester sssd sssd-client --nogpgcheck
		
		authconfig --enableldap --enableldapauth --ldapserver=${AD_PRIVATE_IP} \
			--ldapbasedn="${LDAP_BASE_DN}" --enablemkhomedir --enablecachecreds \
			--enableldaptls --update --enablelocauthorize --enablesssd --enablesssdauth \
			--enablemkhomedir --enablecachecreds
		
		cat > /etc/sssd/sssd.conf <<-EOF
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
			
		EOF
		
		rm -f /var/log/sssd/*.log
		
		chown root:root /etc/sssd/sssd.conf
		chmod 600 /etc/sssd/sssd.conf
		systemctl enable sssd
		systemctl stop sssd
		systemctl restart sssd
		
		pamtester login ad_user1 open_session
		id ad_user1
		getent passwd ad_user1
		getent group DemoTenantUsers
		
	DOCKER_EOF

	# Add Active Directory user and group
	bdmapr maprcli acl edit \
			-cluster hcp.mapr.cluster -type cluster -user ad_admin1:fc

	bdmapr maprcli acl edit \
			-cluster hcp.mapr.cluster -type cluster -group DemoTenantUsers:login,cv

	bdmapr maprcli acl show -type cluster

	# restart the epic-mapr docker instance - we want to test our changes work 
	# after restarting
	docker restart \$(docker ps | grep "epic/mapr" | cut -d " " -f1); docker ps

	# give mapr a chance to startup inside the container
	sleep 120 
SSH_EOF