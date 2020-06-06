#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

command -v python3 >/dev/null 2>&1    || { echo >&2 "I require 'python3' but it's not installed.  Aborting."; exit 1; }
command -v pip3 >/dev/null 2>&1       || { echo >&2 "I require 'pip3' but it's not installed.  Aborting."; exit 1; }

command -v ssh-keygen >/dev/null 2>&1 || { echo >&2 "I require 'ssh-keygen' but it's not installed.  Aborting."; exit 1; }
command -v nc >/dev/null 2>&1         || { echo >&2 "I require 'nc' but it's not installed.  Aborting."; exit 1; }
command -v curl >/dev/null 2>&1       || { echo >&2 "I require 'curl' but it's not installed.  Aborting."; exit 1; }

command -v terraform >/dev/null 2>&1  || { 
    echo >&2 "I require 'terraform' but it's not installed.  Aborting."
    echo >&2 "Please install as per: https://learn.hashicorp.com/terraform/getting-started/install.html"
    exit 1
}

command -v aws >/dev/null 2>&1  || { 
    echo >&2 "I require 'aws' CLI but it's not installed.  Aborting."
    echo >&2 "Please install as per: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html"
    exit 1
}

python3 -m ipcalc > /dev/null || {
    echo "I require 'ipcalc' python module, but it's not installed.  Aborting."
    echo "Please install with: 'pip3 install --user ipcalc six'"
    exit 1
}
