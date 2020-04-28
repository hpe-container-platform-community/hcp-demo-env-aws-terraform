#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

./scripts/check_prerequisites.sh

pip3 install --upgrade git+https://github.com/hpe-container-platform-community/hpecp-client@master

# Configure the Gateway
./scripts/end_user_scripts/hpe_admin/lock_delete_locks.py
./scripts/end_user_scripts/hpe_admin/lock_set.py
./scripts/end_user_scripts/hpe_admin/add_gateway.py
./scripts/end_user_scripts/hpe_admin/lock_delete_locks.py

# Configure AD authentication globally and on the EPIC Demo Tenant
./scripts/end_user_scripts/hpe_admin/configure_authentication.py

# This assumes you are installing four workers
./scripts/end_user_scripts/hpe_admin/worker_add_k8s_host.py $(./generated/get_private_endpoints.sh | grep 'Worker  0' | awk '{ print $3}')
./scripts/end_user_scripts/hpe_admin/worker_add_k8s_host.py $(./generated/get_private_endpoints.sh | grep 'Worker  1' | awk '{ print $3}')
./scripts/end_user_scripts/hpe_admin/worker_add_k8s_host.py $(./generated/get_private_endpoints.sh | grep 'Worker  2' | awk '{ print $3}')
./scripts/end_user_scripts/hpe_admin/worker_add_k8s_host.py $(./generated/get_private_endpoints.sh | grep 'Worker  3' | awk '{ print $3}')
