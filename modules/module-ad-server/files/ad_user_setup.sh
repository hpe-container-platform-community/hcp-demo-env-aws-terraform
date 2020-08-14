#!/bin/bash

# allow weak passwords - easier to demo
samba-tool domain passwordsettings set --complexity=off

# set password expiration to highest possible value, default is 43
samba-tool domain passwordsettings set --max-pwd-age=999

# Create DemoTenantUsers group and a user ad_user1, ad_user2
samba-tool group add DemoTenantUsers
samba-tool user create ad_user1 pass123
samba-tool group addmembers DemoTenantUsers ad_user1

samba-tool user create ad_user2 pass123
samba-tool group addmembers DemoTenantUsers ad_user2

# Create DemoTenantAdmins group and a user ad_admin1, ad_admin2
samba-tool group add DemoTenantAdmins
samba-tool user create ad_admin1 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin1

samba-tool user create ad_admin2 pass123
samba-tool group addmembers DemoTenantAdmins ad_admin2