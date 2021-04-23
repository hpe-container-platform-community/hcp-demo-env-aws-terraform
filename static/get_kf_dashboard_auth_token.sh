#!/bin/bash 

set -e
set -o pipefail


if [[ -z $3 ]]; then
  echo Usage: $0 TENANT_ID USERNAME PASSWORD
  exit 1
fi

set -u

export PATH=$PATH:~/.local/bin

export TENANT_ID=$1
export CLUSTER_ID=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [k8s_cluster]" --output text)

KFURL="https://$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    describe svc/istio-ingressgateway -n istio-system \
      | grep hpecp-internal-gateway/80: \
      | sed -e 's/^[ \t]*hpecp-internal-gateway\/80: //')"

UNAME="$2"
PSWRD="$3"

#echo KFURL=$KFURL

STATE=$(curl -s -k ${KFURL} | grep -oP '(?<=state=)[^ ]*"' | cut -d \" -f1)
REQ=$(curl -s -k "${KFURL}/dex/auth?client_id=kubeflow-oidc-authservice&redirect_uri=%2Flogin%2Foidc&response_type=code&scope=profile+email+groups+openid&amp;state=$STATE" | grep -oP '(?<=req=)\w+')

curl -s -k "${KFURL}/dex/auth/ad?req=$REQ" -H 'Content-Type: application/x-www-form-urlencoded' --data "login=$UNAME&password=$PSWRD"
  
CODE=$(curl -s -k "${KFURL}/dex/approval?req=$REQ" | grep -oP '(?<=code=)\w+')
ret=$?
if [ $ret -ne 0 ]; then
    echo "Error"
    exit 1
fi
curl -s -k --cookie-jar - "${KFURL}/login/oidc?code=$CODE&amp;state=$STATE" > .dex_session

AUTH_TOKEN=$(cat .dex_session | grep 'authservice_session' | awk '{ORS="" ; printf "%s", $NF}')
echo $AUTH_TOKEN