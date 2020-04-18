## Overview

Based on ...

- https://github.com/halo/macosvpn
- https://www.softether.org/
- https://hub.docker.com/r/siomiz/softethervpn/ (at the time of writing, this uses the latest RFM release of SoftEther)

Note:

- The vpn server is only accessible to whitelisted IP addresses using the terraform created AWS Network ACL and Security Groups.
- SoftEther is used because it does not have the 2 user limitation like OpenVPN.

##  Mac Setup

- run `sudo ./generated/mac_vpn_connect.sh` to create vpn and to connect to it
- run `sudo ./generated/mac_vpn_delete.sh` to delete the vpn
- run `sudo ./generated/mac_vpn_status.sh` to report on the vpn status

The VPN server is provided by SoftEther on the RDP Linux server.


