## Overview

An Active Directory Server is recommended for demo and trial environments.

## Pre-requisites

- None

## Learning Content

The steps below show how to configure an Active Directory server with the user and group accounts that are used in the tutorials in the learning path.

### Terraform managed environment

- On Terraform managed environments you can install a pre-configured AD Server as documented [here](../docs/README-AD.md)

### Manually installed environments

The scripts below assume Centos, please modify for other environments.

- Create user setup script

```
cat > /home/centos/ad_user_setup.sh <<-EOT
      #!/bin/bash
      
      # allow weak passwords - easier to demo
      samba-tool domain passwordsettings set --complexity=off
      
      # set password expiration to highest possible value, default is 43
      samba-tool domain passwordsettings set --max-pwd-age=999
    
      # Create DemoTenantUsers group and a user ad_user1
      samba-tool group add DemoTenantUsers
      samba-tool user create ad_user1 pass123
      
      samba-tool group addmembers DemoTenantUsers ad_user1
      # Create DemoTenantAdmins group and a user ad_admin1
      samba-tool group add DemoTenantAdmins
      samba-tool user create ad_admin1 pass123
      samba-tool group addmembers DemoTenantAdmins ad_admin1
EOT
```

- Run the docker instance

```
sudo yum install -y docker openldap-clients
sudo service docker start
sudo systemctl enable docker
sudo docker run --privileged --restart=unless-stopped \
    -p 53:53 -p 53:53/udp -p 88:88 -p 88:88/udp -p 135:135 -p 137-138:137-138/udp -p 139:139 -p 389:389 \
    -p 389:389/udp -p 445:445 -p 464:464 -p 464:464/udp -p 636:636 -p 1024-1044:1024-1044 -p 3268-3269:3268-3269 \
    -e "SAMBA_DOMAIN=samdom" \
    -e "SAMBA_REALM=samdom.example.com" \
    -e "SAMBA_ADMIN_PASSWORD=5ambaPwd@" \
    -e "ROOT_PASSWORD=R00tPwd@" \
    -e "LDAP_ALLOW_INSECURE=true" \
    -e "SAMBA_HOST_IP=$(hostname --all-ip-addresses |cut -f 1 -d' ')" \
    -v /home/centos/ad_user_setup.sh:/usr/local/bin/custom.sh \
    --name samdom \
    --dns 127.0.0.1 \
    -d \
    --entrypoint "/bin/bash" \
    rsippl/samba-ad-dc \
    -c "chmod +x /usr/local/bin/custom.sh &&. /init.sh app:start"
```

- Modify users - step 1 create LDIF

```
 cat > /home/centos/ad_set_posix_classes.ldif <<-EOT
      # DemoTenantAdmins
      dn: cn=DemoTenantAdmins,cn=Users,DC=samdom,DC=example,DC=com
      changetype: modify
      add:objectclass
      objectclass: posixGroup
      -
      add: gidnumber
      gidnumber: 10001
      # ad_admin1
      dn: cn=ad_admin1,cn=Users,DC=samdom,DC=example,DC=com
      changetype: modify
      add:objectclass
      objectclass: posixAccount
      -
      add: uidNumber
      uidNumber: 20001
      -
      add: gidnumber
      gidnumber: 10001
      -
      add: unixHomeDirectory
      unixHomeDirectory: /home/ad_admin1
      -
      add: loginShell
      loginShell: /bin/bash
      -
      add: mail
      mail: adadmin1@example.com
      -
      add: givenName
      givenName: ADAdmin1
      # DemoTenantUsers
      dn: cn=DemoTenantUsers,cn=Users,DC=samdom,DC=example,DC=com
      changetype: modify
      add:objectclass
      objectclass: posixGroup
      -
      add: gidnumber
      gidnumber: 10002
      # ad_admin1
      dn: cn=ad_user1,cn=Users,DC=samdom,DC=example,DC=com
      changetype: modify
      add:objectclass
      objectclass: posixAccount
      -
      add: uidNumber
      uidNumber: 20002
      -
      add: gidnumber
      gidnumber: 10002
      -
      add: unixHomeDirectory
      unixHomeDirectory: /home/ad_user1
      -
      add: loginShell
      loginShell: /bin/bash
      -
      add: mail
      mail: aduser1@example.com
      -
      add: givenName
      givenName: ADUser1
EOT
```

- Modify users - step 2, apply LDIF

```
ldapmodify -H ldap://localhost:389 \
   -D 'cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com' \
   -f /home/centos/ad_set_posix_classes.ldif \
   -w '5ambaPwd@' \
   -c 2>&1 >ad_set_posix_classes.log
```


## Learning Summary

In this section, you have been walked through setting up an Active Directory Server.
