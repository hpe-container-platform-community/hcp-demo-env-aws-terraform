### Active Directory

If you want the terraform script to deploy an AD server, set `ad_server_enabled=true` in your `bluedata_infra.tfvars` file.

You will need to run `terraform apply ...` after making the update.  

Run `terraform output ad_server_private_ip` to get the AD server IP address - you will need this when configuring the BlueData UI.

```
System Settings -> User Authentication
   -> Authentication Type: Active Directory
   -> Security Protocol: LDAPS
   -> Service Location: ${ad_server_private_ip} | Port: 636
   -> Bind Type: Search Bind
   -> User Attribute: sAMAccountName
   -> Base DN: CN=Users,DC=samdom,DC=example,DC=com
   -> Bind DN: cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com
   -> Bind Password: 5ambaPwd@
```

Two AD groups and two AD users were created automatically when the enviroment was provisioned:

- `DemoTenantAdmins` group
- `DemoTenantUsers` group
- `ad_user1` and `ad_user2` in the `DemoTenantUsers` group with password `pass123`
- `ad_admin1` and `ad_admin2` in the `DemoTenantAdmins` group with password `pass123`

#### Adding an AD user

To add an additional users, on your client machine open a shell session inside your cloned repo directory and paste the following command:

```
# Retrieve the SSH command to access the AD instance
SSH_CMD=$(terraform output ad_server_ssh_command)

# Add a new AD group
$SSH_CMD sudo docker exec samdom samba-tool group add DemoTenantAdmins

# Create the user
$SSH_CMD sudo docker exec samdom samba-tool user create demo_user pass123

# Add user to the group
$SSH_CMD sudo docker exec samdom samba-tool group addmembers DemoTenantAdmins demo_user
```

NOTE: Users created on the environment are not persisted so they will be lost if you terminate the instance.

#### Tenant Setup

Recommended reading: http://docs.bluedata.com/40_authentication-groups

E.g. Demo Tenant 

```
Tenant Settings
  -> External User Groups: CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com | Admin
  -> External User Groups: CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com | Member
```

- Login to BlueData as `ad_admin1/pass123` - you should be taken to the Demo Tenant and have 'Admin' privileges
- Create a new user (see below)
- Login to BlueData as `ad_user1/pass123` - you should be taken to the Demo Tenant and have 'Member' privileges

#### Provision Cluster

- Login as AD credentials `ad_user1/pass123`
- Provision a spark cluster (e.g. `bluedata/spark231juphub7x-ssl`) - you only need 1 small Jupyterhub node
- Click the Jupyterhub URL to launch jupyter
- Login with AD credentials `ad_user1/pass123`
- SSH into the cluster `ssh ad_user1@THE_IP_ADDR -p THE_PORT` - use your AD password: `pass123` 
  - try `groups` to list your AD groups 
  - try `sudo ls /` you should be denied after entering your password
- SSH into the cluster `ssh ad_admin1@THE_IP_ADDR -p THE_PORT` - use your AD password: `pass123` 
  - try `groups` to list your AD groups
  - try `sudo ls /` you should be allowed to sudo due to the Tentant setting


### Directory Browser

Sometimes it's useful to browse the AD tree with a graphical interface.  This section describes how to connect with the open source Apache Directory Studio.

- Download and install Apache Director Studio
- Run `$(terraform output ad_server_ssh_command) -L 1636:localhost:636` - this retrieves from the terraform environment the ssh command required to connect to the AD EC2 instance.  The `-L 1636:localhost:636` command tells ssh to bind to port `1636` on your local machine and forward traffic to the port `636` on the AD EC2 instance.  Exiting the ssh session will remove the port binding.
- In Apache Directory Studio, create a new connection:
  - *Connection name:* choose something meaningful
  - *Hostname:* localhost
  - *Port:* 1636
  - *Connection timeout(s):* 30
  - *Encryption method:* No encryption
  - *Provider:* Apache Directory LDAP Client API
  - **Click *Next***
  - *Authentication Method:* Simple Authentication
  - *Bind DN or user:* cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com
  - *Bind password:* 5ambaPwd@
  - **Click *Finish***
