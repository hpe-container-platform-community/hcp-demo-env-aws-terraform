#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/variables.sh"

echo ADDITIONAL_CLIENT_IP_LIST="${ADDITIONAL_CLIENT_IP_LIST}"
