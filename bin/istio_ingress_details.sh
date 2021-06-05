#!/usr/bin/env bash

set -e
set -o pipefail

if [[ -z $1 ]]; then
  echo Usage: $0 CLUSTERNAME
  exit 1
fi

CLUSTERNAME=$1

set -u

source ./scripts/check_prerequisites.sh
source ./scripts/variables.sh

ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF
  
  echo -n "Host IPs: "
  kubectl --kubeconfig <(./get_admin_kubeconfig.sh $CLUSTERNAME) get po -l istio=ingressgateway -n istio-system \
     -o jsonpath='{.items[*].status.hostIP}'
  echo

  echo -n "HTTP Port: "
  kubectl --kubeconfig <(./get_admin_kubeconfig.sh $CLUSTERNAME) -n istio-system get service istio-ingressgateway \
     -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
  echo

  echo -n "HTTPS Port: "
  kubectl --kubeconfig <(./get_admin_kubeconfig.sh $CLUSTERNAME) -n istio-system get service istio-ingressgateway \
     -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}'
  echo

  echo -n "TCP Port: "
  kubectl --kubeconfig <(./get_admin_kubeconfig.sh $CLUSTERNAME) -n istio-system get service istio-ingressgateway \
     -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}'
  echo

EOF