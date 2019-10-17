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

Two AD users were created automatically when the enviroment was provisioned:

- ad_user1 in the "Users" group with password = Passw0rd
- ad_admin1 in the "Administrators" group with password = Passw0rd

#### Adding an AD user

To add an additional users, on your client machine open a shell session inside your cloned repo directory and paste the following command:

```
function create_user {
   # Set USERNAME, PASSWORD and GROUP as required
   USERNAME=$1
   PASSWORD=$2

   # Administrators | Users
   GROUP=$3

   # SSH Command String
   SSH_CMD=$(terraform output ad_server_ssh_command)

   # Create the user
   $SSH_CMD sudo docker exec samdom samba-tool user create $USERNAME $PASSWORD

   # Add user to the group
   $SSH_CMD sudo docker exec samdom samba-tool group addmembers "$GROUP" $USERNAME
}

# create a user in the "Users" group
create_user user1 Passw0rd Users

# create a user in the "Administrators" group
create_user admin1 Passw0rd Administrators
```

NOTE: Users created on the environment are not persisted so they will be lost if you terminate the instance.

#### Tenant Setup

Recommended reading: http://docs.bluedata.com/40_authentication-groups

E.g. Demo Tenant 

```
Tenant Settings
  -> External User Groups: CN=Administrators,CN=Builtin,DC=samdom,DC=example,DC=com | Admin
  -> External User Groups: CN=Users,CN=Builtin,DC=samdom,DC=example,DC=com | Member
```

- Login to BlueData as `admin1/Passw0rd` - you should be taken to the Demo Tenant and have 'Admin' privileges
- Create a new user (see below)
- Login to BlueData as `user1/Passw0rd` - you should be taken to the Demo Tenant and have 'Member' privileges

#### Provision Cluster

- Login as AD credentials `user1/Passw0rd`
- Provision a spark cluster (e.g. `bluedata/spark231juphub7x-ssl`) - you only need 1 small Jupyterhub node
- Click the Jupyterhub URL to launch jupyter
- Login with AD credentials `user1/Passw0rd`
- SSH into the cluster `ssh user1@THE_IP_ADDR -p THE_PORT` - use your AD password: `Passw0rd`

### Directory Browser

Sometimes it's useful to browse the AD tree with a graphical interface.  This section describes how to connect with the open source Apache Directory Studio.

- Download and install Apache Director Studio
- Run `$(terraform output ad_server_ssh_command) -L 1636:localhost:636` - this retrieves from the terraform environment the ssh command required to connect to the AD EC2 instance.  The `-L 1636:localhost:636` command tells ssh to bind to port `1636` on your local machine and forward traffic to the port `636` on the AD EC2 instance. 
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