#!/bin/bash

HOST_IPS=( "$@" )

set -e # abort on error
set -u # abort on undefined variable

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

pip3 install --quiet --upgrade --user hpecp

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
echo "Platform ID: $(hpecp license platform-id)"

PROFILE=tenant2 hpecp httpclient post /api/v2/cluster/  <(echo '
{
  "isolated": false,
  "label": {
    "name": "spark cluster 1",
    "description": ""
  },
  "dependent_nodegroups": [],
  "debug": false,
  "two_phase_delete": false,
  "nodegroup": {
    "role_configs": [
      {
        "node_count": 1,
        "flavor": "/api/v1/flavor/3",
        "role_id": "controller"
      },
      {
        "node_count": 0,
        "flavor": "/api/v1/flavor/1",
        "role_id": "worker"
      },
      {
        "node_count": 0,
        "flavor": "/api/v1/flavor/1",
        "role_id": "jupyter"
      },
      {
        "node_count": 1,
        "flavor": "/api/v1/flavor/3",
        "role_id": "jupyterhub"
      },
      {
        "node_count": 0,
        "flavor": "/api/v1/flavor/1",
        "role_id": "rstudio"
      },
      {
        "node_count": 0,
        "flavor": "/api/v1/flavor/1",
        "role_id": "gateway"
      }
    ],
    "catalog_entry_distro_id": "bluedata/spark231juphub7xssl",
    "config_choice_selections": [],
    "constraints": []
  }
}
')