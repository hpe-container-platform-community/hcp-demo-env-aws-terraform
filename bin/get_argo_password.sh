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

ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  CLUSTERNAME=$CLUSTERNAME

  echo username: admin
  echo -n "password: "
  
  kubectl --kubeconfig <(./get_admin_kubeconfig.sh $CLUSTERNAME) get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2

EOF1