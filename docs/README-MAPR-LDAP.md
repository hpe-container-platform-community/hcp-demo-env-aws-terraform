### Instructions for setting up LDAP in MapR

See here for more info: http://docs.bluedata.com/50_mapr-control-system

These instructions assume you have deployed the AD server by setting `ad_server_enabled=true` in your `bluedata_infra.tfvars` file.  You will need to run `terraform apply ...` after making the update.  

After `terraform apply`, run `terraform output ad_server_private_ip` to get the AD server IP address.

SSH into the controller, then run:

```
# start epic-mapr container: 
bdmapr --root bash

AD_PRIVATE_IP="10.1.0.234" # populate with output from ad_server_private_ip

### DONT CHANGE BELOW THIS LINE

LDAP_BASE_DN="CN=Users,DC=samdom,DC=example,DC=com"
LDAP_BIND_DN="cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com" # the ad server in the demo environment has been created with this DN
LDAP_BIND_PASSWORD="5ambaPwd@"
LDAP_ACCESS_FILTER="CN=Users,CN=Builtin,DC=samdom,DC=example,DC=com"
DOMAIN="samdom.example.com"

# Install the auth packages by executing the following command 
# TODO: really disable pgpcheck??
yum install -y authconfig openldap openldap-clients pamtester sssd sssd-client --nogpgcheck

authconfig --enableldap --enableldapauth --ldapserver=${AD_PRIVATE_IP} --ldapbasedn="${LDAP_BASE_DN}" --enablemkhomedir --enablecachecreds --enableldaptls --update --enablelocauthorize --enablesssd --enablesssdauth --enablemkhomedir --enablecachecreds

cat > /etc/sssd/sssd.conf <<EOF
[domain/${DOMAIN}]
debug_level = 6
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
ldap_id_mapping = True
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

# Uncomment the following to debug
tail -f /var/log/sssd/**

# tail -f /opt/mapr/logs/apiserver.log /var/log/sssd/**
# ldapsearch -o ldif-wrap=no -x -D 'cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com' -w '5ambaPwd@' -b 'DC=samdom,DC=example,DC=com' '(cn=ad_user1)'

```