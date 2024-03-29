#!/usr/bin/env bash

set -e
set -o pipefail

if [[ -z $1 ]]; then
  echo Usage: $0 WORKER_ID
  echo Where: WORKER_ID = /api/v2/worker/k8shost/[0-9]*
  exit 1
fi

WORKER_ID=$1

set -u

source ./scripts/check_prerequisites.sh
source ./scripts/variables.sh

hpecp k8sworker list -query "[?_links.self.href == '${WORKER_ID}'] | [0] | [ipaddr]" -o text