#!/bin/bash

WORKER_ID=$1

source "./scripts/variables.sh"

if [[ -z "${WORKER_ID##*[!0-9]*}" ]];
then
    echo Usage: $0 ID [ARG1, ARG2, ...]
    echo
    printf "ID\tIP\n"
    for i in "${!WRKR_PUB_IPS[@]}"; do
      printf "%s\t%s\n" "$i" "${WRKR_PUB_IPS[$i]}"
    done
    exit 1
fi

ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@${WRKR_PUB_IPS[$WORKER_ID]} "${@:2}"
