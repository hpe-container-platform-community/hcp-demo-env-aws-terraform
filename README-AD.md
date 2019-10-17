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

- ad_user1 in the "Users" group
- ad_admin1 in the "Administrators" group

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

