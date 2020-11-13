#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

source "./scripts/variables.sh"
  
if [[ "$EUID" != "0" ]]; then
  echo "This script must be run as root - e.g. with sudo" 
  exit 1
fi

USER_BEFORE_SUDO=$(who am i | awk '{print $1}')

if [[ ! -f "./generated/vpn_users" ]]; then
    echo "ERROR: './generated/vpn_users' not found - have you run './bin/vpn_server_setup.sh'?"
    exit 1
fi

sudo -u $USER_BEFORE_SUDO ./bin/vpn_server_setup.sh

VPN_USERS=$(sudo -u $USER_BEFORE_SUDO cat "./generated/vpn_users")
VPN_PSK=$(sudo -u $USER_BEFORE_SUDO cat "./generated/vpn_shared_key")

if ! sudo -u $USER_BEFORE_SUDO command -v macosvpn >/dev/null 2>&1; then 
  echo "'macosvpn' is required but it's not installed.  You can install it with 'brew install macosvpn'.  Aborting.";
  exit 1
fi

VPN_USER=$(echo $VPN_USERS | cut -d ":" -f1)
VPN_PASS=$(echo $VPN_USERS | cut -d ":" -f2)

macosvpn create --l2tp hpe-container-platform-aws \
                        --force \
                        --endpoint $(terraform output rdp_server_public_ip) \
                        --username $VPN_USER \
                        --password $VPN_PASS \
                        --sharedsecret $VPN_PSK \
                        --split # Do not send all traffic across VPN tunnel

echo "Waiting 10s for vpn settings to save"
sleep 10
sudo -u $USER_BEFORE_SUDO /usr/sbin/networksetup -connectpppoeservice "hpe-container-platform-aws"
    
echo "Waiting 10s for VPN to start"
sleep 10

# VPN Status
scutil --nc list | grep hpe-container-platform-aws

route -n delete -net $(terraform output vpc_cidr_block) $(terraform output softether_rdp_ip) || true # ignore error
route -n add -net $(terraform output vpc_cidr_block) $(terraform output softether_rdp_ip)

# VPC DNS Server is base of VPC network range plus 2 - https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html
VPC_DNS_SERVER=$(python3 -c "import ipcalc; print(str((ipcalc.Network('$VPC_CIDR_BLOCK')+2)).split('/')[0])")
networksetup -setdnsservers hpe-container-platform-aws $VPC_DNS_SERVER
echo "VPN DNS set to: $(networksetup -getdnsservers hpe-container-platform-aws)"

echo "Looking up controller private dns with dig"
dig @$VPC_DNS_SERVER $(terraform output controller_private_dns)

echo "Attempting to ping the controller private IP ..."
ping -c 5 $CTRL_PRV_IP

echo "******************************************************************************"
echo "                                 IMPORTANT"
echo "******************************************************************************"
if [[ "$CREATE_EIP_RDP_LINUX_SERVER" == "False" ]]; then
echo "- You need to run this script every time you restart your instances to update"
echo "  the VPN with the RDP server new public IP address."
else
echo "- You are using a EIP for the RDP server, you can connect/disconnect the vpn"
echo "  using the tools provided with your OS."
fi
echo "*****************************************************************************"
