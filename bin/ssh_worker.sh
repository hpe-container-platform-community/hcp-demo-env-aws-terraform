#!/bin/bash

WORKER_ID=$1

source "./scripts/variables.sh"

print_workers() {
    printf "ID\tPUB IP\t\tPRV IP\n"
    for i in "${!WRKR_PUB_IPS[@]}"; do
      printf "%s\t%s\t%s\n" "$i" "${WRKR_PUB_IPS[$i]}" "${WRKR_PRV_IPS[$i]}"
    done
}

if [[ -z "${WORKER_ID##*[!0-9]*}" ]];
then
    echo Usage: $0 ID [ARG1, ARG2, ...]
    echo
    print_workers
    exit 1
fi

if [[ $WORKER_ID -lt 0 || $WORKER_ID -gt ${#WRKR_PUB_IPS[@]}-1 ]]; 
then
  echo "$(tput setaf 1)Invalid worker id: $WORKER_ID$(tput sgr0)"
  print_workers
  exit 1
fi

ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@${WRKR_PUB_IPS[$WORKER_ID]} "${@:2}"
