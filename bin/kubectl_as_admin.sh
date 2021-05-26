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
  kubectl --kubeconfig <(./get_admin_kubeconfig.sh $CLUSTERNAME) ${@:2}
EOF