#!/bin/bash 

  set -e
  set -o pipefail


if [[ -z $3 ]]; then
  echo Usage: $0 TENANT_ID USERNAME PASSWORD
  exit 1
fi

set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

export TENANT_ID=$1

KFURL="https://$(./bin/get_kf_dashboard_url.sh $TENANT_ID)"
UNAME="$2"
PSWRD="$3"


ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  set -e
  
  STATE=\$(curl -s -k ${KFURL} | grep -oP '(?<=state=)[^ ]*"' | cut -d \" -f1)

  REQ=\$(curl -s -k "${KFURL}/dex/auth?client_id=kubeflow-oidc-authservice&redirect_uri=%2Flogin%2Foidc&response_type=code&scope=profile+email+groups+openid&amp;state=\$STATE" | grep -oP '(?<=req=)\w+')

  curl -s -k "${KFURL}/dex/auth/ad?req=\$REQ" -H 'Content-Type: application/x-www-form-urlencoded' --data "login=$UNAME&password=$PSWRD"
  
  CODE=\$(curl -s -k "${KFURL}/dex/approval?req=\$REQ" | grep -oP '(?<=code=)\w+')
  ret=\$?
  if [ \$ret -ne 0 ]; then
      echo "Error"
      exit 1
  fi
  curl -s -k --cookie-jar - "${KFURL}/login/oidc?code=\$CODE&amp;state=\$STATE" > .dex_session

  echo \$(cat .dex_session | grep 'authservice_session' | awk '{ORS="" ; printf "%s", \$NF}')

EOF1