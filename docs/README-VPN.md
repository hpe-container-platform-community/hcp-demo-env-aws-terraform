## Overview

Based on ...

- https://github.com/halo/macosvpn
- https://www.softether.org/
- https://hub.docker.com/r/siomiz/softethervpn/ (at the time of writing, this uses the latest RFM release of SoftEther)

Note:

- The vpn server is only accessible to whitelisted IP addresses using the terraform created AWS Network ACL and Security Groups.
- SoftEther is used because it does not have the 2 user limitation like OpenVPN.

##  Mac Setup

Run `sudo ./generated/mac_vpn_setup.sh`

This configures and runs SoftEther vpn software on the RDP Linux server and sets up the Mac VPN client.

TODO: 

- script to check vpn status
- script to stop vpn

