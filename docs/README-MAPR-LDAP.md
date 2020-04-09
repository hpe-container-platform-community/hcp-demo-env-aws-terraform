## Experimental Instructions for setting up LDAP in MapR

See here for more info: http://docs.bluedata.com/50_mapr-control-system

### Pre-requisites

These instructions assume you have deployed the AD server by setting `ad_server_enabled=true` in your `bluedata_infra.tfvars` file.  You will need to run `terraform apply ...` after making the update.  

After `terraform apply`, run `terraform output ad_server_private_ip` to get the AD server IP address.

### Configure the epic-mapr docker container

SSH into the controller, then run the following to open a shell session in the epic-mapr container:

```
# start epic-mapr container: 
bdmapr --root bash
```

Next change the AD_PRIVATE_IP address below, and run the whole script from your epic-mapr session:

```
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

```

Exit the epic-mapr session so you are back on the controller and restart the epic-mapr container:

```
docker restart $(docker ps | grep "epic/mapr" | cut -d " " -f1); docker ps
```

### Configure users in MCS

You can now login to the MapR MCS as the admin user (see [here](http://docs.bluedata.com/50_mapr-control-system) for instructions login into MCS).

From the **Admin** menu, select **User Settings**

![User Settings](./README-MAPR-LDAP/user_settings.png)

We can add Active Directory users or groups.  Refer to [./README-AD.md](./README-AD.md) for information on the deploying an Active Directory server that is preconfigured with several users and groups for you to experiment with.

Add the Active Directory admin user **ad_admin1** as follows

![Add AD Admin User](./README-MAPR-LDAP/add_ad_admin_user.png)

Add the Active Directory group **DemoTenantUser** as follows

![Add AD User Group](./README-MAPR-LDAP/add_ad_user_group.png)

### Log into MCS with AD users

First try log on as the **ad_admin1** user.

![Login as AD Admin User](./README-MAPR-LDAP/login_ad_admin1.png)

Now log out and log on as with a user in the **DemoTenantUser** group, e.g. **ad_user1**

![Login as AD User](./README-MAPR-LDAP/login_ad_user1.png)

You can experiment to verify each user has the permissions that you set when adding the user and group.

### Create a Volume

Shortly, we will create a volume.  We want to mount the volume into the global name space, so first we need to setup a folder in the epic-mapr container.

From a ssh session on the controller, start a shell session in the epic-mapr container:

```
bdmapr --root bash
```

Now create a folder in the global name space `/shared`:


```
mkdir /mapr/mnt/hcp.mapr.cluster/shared
chmod 777 /mapr/mnt/hcp.mapr.cluster/shared
chown -R mapr:mapr /mapr/mnt/hcp.mapr.cluster/shared
```

We can now create a Volume in MCS (**ensure you login as the MAPR 'admin' user and not an active directory user**).

![Volume Menu](./README-MAPR-LDAP/volume_menu.png)

Next click on create Volume:

![Create Volume Button](./README-MAPR-LDAP/create_volume_button.png)

Define the settings for the volume

![Create Volume](./README-MAPR-LDAP/create_volume.png)

**TIP:** We are creating the volume in the `/data` topology - in practice it is recommended to use a separate topology because `/data` is is used for system objects such as monitoring and tenant storage.

Next we need to define the authorization for the volume.  I have decided to give the **ad_admin1** user full administrative access and the **DemoTenantUsers** read/write access.

![Set volume authorization](./README-MAPR-LDAP/volume_authorization.png)

Next set the permissions for the new shared volume. 

From a ssh session on the controller, open a session on the container:

```
bdmapr --root bash
```

Now set the permissions

```
chown -R ad_admin1:DemoTenantUsers /mapr/mnt/hcp.mapr.cluster/shared/shared-vol
chmod -R 775 /mapr/mnt/hcp.mapr.cluster/shared/shared-vol
```

---

## AD client

### Configure AD client on RDP (client) host

Open a ssh session on the RDP host, then run the following:

```
AD_PRIVATE_IP="10.1.0.158" # populate with output from ad_server_private_ip

### DONT CHANGE BELOW THIS LINE

LDAP_BASE_DN="CN=Users,DC=samdom,DC=example,DC=com"
LDAP_BIND_DN="cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com" # the ad server in the demo environment has been created with this DN
LDAP_BIND_PASSWORD="5ambaPwd@"
LDAP_ACCESS_FILTER="CN=Users,CN=Builtin,DC=samdom,DC=example,DC=com"
DOMAIN="samdom.example.com"

# Install the auth packages by executing the following command 
# TODO: really disable pgpcheck??
sudo apt install -y pamtester sssd 

cat > /tmp/sssd.conf <<EOF
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
ldap_id_mapping = True
ldap_schema = ad
ldap_user_gid_number = gidNumber
ldap_group_gid_number = gidNumber
ldap_user_object_class = posixAccount
ldap_idmap_range_size = 200000
ldap_user_gecos = gecos
fallback_homedir = /home/%u
ldap_user_home_directory = homeDirectory
override_homedir = /home/%u
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
sudo mv /tmp/sssd.conf /etc/sssd/sssd.conf

sudo chown root:root /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
sudo systemctl enable sssd
sudo systemctl stop sssd
sudo systemctl restart sssd

pamtester login ad_user1 open_session
id ad_user1
getent passwd ad_user1
getent group DemoTenantUsers
```

We want the user to have a home directory created.  Edit /etc/pam.d/common-session, and add this line directly after `session required pam_unix.so`:

```
session    required    pam_mkhomedir.so skel=/etc/skel/ umask=0022
```

### Configure MAPR POSIX Client on RDP (client) host

From RDP (client) host 

```
CTRL_IP="10.1.0.35" # Change this to your controller IP address

sudo bash -c \"echo 'deb https://package.mapr.com/releases/v6.1.0/ubuntu binary trusty' > /etc/apt/sources.list.d/mapr.list\"
wget -O - https://package.mapr.com/releases/pub/maprgpg.key | sudo apt-key add -
sudo apt install mapr-posix-client-basic
sudo modprobe fuse

# Create required mapr:mapr user/group
sudo groupadd -g 5000 mapr
sudo useradd -u 5000 -s /bin/bash -d /home/mapr -g 5000 mapr

# Replace IP addresses with HCP controller private IP
sudo /opt/mapr/server/configure.sh -N hcp.mapr.cluster -C ${CTRL_IP} -Z ${CTRL_IP} -c -secure
```

From RDP (client) host 

```
# get the ssl_truststore from MapR container
ssh centos@${CTRL_IP} docker cp epic-mapr:/opt/mapr/conf/ssl_truststore .
scp centos@${CTRL_IP}:~/ssl_truststore .
sudo cp ssl_truststore /opt/mapr/conf/
sudo chown root:root /opt/mapr/conf/ssl_truststore

sudo su - ad_admin1
maprlogin password -user ad_admin1 -cluster hcp.mapr.cluster
```

Enter `pass123` at the above prompt.

```
# Create service ticket as ad_admin1 (to impersonate)
maprlogin generateticket -type servicewithimpersonation -user ad_admin1 -out maprfuseticket

exit # return to ubuntu/local user
sudo cp /home/ad_admin1/maprfuseticket /opt/mapr/conf/

sudo mkdir /mapr
sudo service mapr-posix-client-basic start

```

### Test

```
$ ll /mapr/hcp.mapr.cluster/shared
```

