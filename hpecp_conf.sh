#!/bin/bash

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
    export HPECP_CONFIG_FILE=./generated/hpecp.conf
    source <(hpecp autocomplete bash)
else
    echo Usage: . $0
fi


