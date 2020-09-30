#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

source "./scripts/variables.sh"

echo RDP_SERVER_ENABLED=$RDP_SERVER_ENABLED
echo RDP_SERVER_OPERATING_SYSTEM=$RDP_SERVER_OPERATING_SYSTEM

if [[ "$RDP_SERVER_ENABLED" != "True" && "$RDP_SERVER_OPERATING_SYSTEM" != "LINUX" ]]
then
   echo "Aborting.  RDP Linux Server has not been enabled in etc/bluedata_infra.tfvars"
   exit 1
fi

echo "Testing connectivity to $RDP_PUB_IP"
ping -c 2 $RDP_PUB_IP || {
   echo "$(tput setaf 1)Aborting. Could not ping RDP Linux Server."
   echo " - You may need to disconnect from your corporate VPN, and/or"
   echo " - You may need to run ./bin/terraform_apply.sh$(tput sgr0)"
   exit 1
}

if [[ ! -f "./generated/vpn_users" ]]; then
    echo user1:$(openssl rand -hex 12 | tr -d '\n') > "./generated/vpn_users"
    echo $(openssl rand -hex 30 | tr -d '\n') > "./generated/vpn_shared_key"
fi

VPN_USERS=$(cat "./generated/vpn_users")
VPN_PSK=$(cat "./generated/vpn_shared_key")

ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" ubuntu@$RDP_PUB_IP <<-SSH_EOF
  set -eux
  sudo ufw allow 1701
  if docker ps | grep softethervpn; then
    docker kill \$(docker ps | grep softethervpn | awk '{ print \$1 }')
  fi
  docker run -d --cap-add NET_ADMIN --restart=always -e USERS="$VPN_USERS" -e PSK="$VPN_PSK" -p 500:500/udp -p 4500:4500/udp -p 1701:1701/tcp -p 1194:1194/udp -p 5555:5555/tcp siomiz/softethervpn
SSH_EOF
