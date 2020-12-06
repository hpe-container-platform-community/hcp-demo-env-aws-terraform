#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

if [[ ! -d generated ]]; then
   echo "This file should be executed from the project directory"
   exit 1
fi

./scripts/check_prerequisites.sh
source ./scripts/variables.sh


ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} <<-SSH_EOF
	set -e
  cd /srv/bluedata/catalog
  rm -f bdcatalog-centos7-ezmeral-spark3-*.bin*
  wget -c --progress=bar -e dotbytes=10M https://riteshj.s3.amazonaws.com/bdcatalog-centos7-ezmeral-spark3-1.0.2.bin
SSH_EOF


pip3 install --quiet --upgrade --user hpecp

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

# Test CLI is able to connect
echo "Platform ID: $(hpecp license platform-id)"

hpecp httpclient post /api/v1/catalog <(echo "{\"action\":\"refresh\"}")

CATALOG_IMAGES=$(hpecp catalog list --query "[? contains(label.name, 'Spark 3.0.0 with Jupyterhub')] | [?state!='installed' && state!='installing' && state!='verifying' && state!='downloading'] | [*].[_links.self.href] | []"  --output text)
for IMG_ID in $CATALOG_IMAGES
do
  echo "Installing: $IMG_ID"
  hpecp catalog install $IMG_ID

  for _ in {1..1000}; do
    STATE=$(hpecp catalog list --query "[?_links.self.href=='${IMG_ID}'] | [*].[state]" --output text)
    echo "State: $STATE"
    if [[ "$STATE" == "installed" ]]; then
      break
    else
      sleep 60
    fi
  done
done


CLUSTER_NAME="spark cluster $(openssl rand -hex 12)"
DISTRO_ID="$(hpecp catalog list --query "[? contains(label.name, 'Spark 3.0.0 with Jupyterhub')] | [0] | [distro_id]" --output text)"
PROFILE=tenant2 hpecp httpclient post /api/v2/cluster/  <(echo "
{
  \"isolated\": false,
  \"label\": {
    \"name\": \"${CLUSTER_NAME}\",
    \"description\": \"\"
  },
  \"dependent_nodegroups\": [],
  \"debug\": false,
  \"two_phase_delete\": false,
  \"nodegroup\": {
    \"role_configs\": [
      {
        \"node_count\": 1,
        \"flavor\": \"/api/v1/flavor/3\",
        \"role_id\": \"spark-master\"
      },
      {
        \"node_count\": 1,
        \"flavor\": \"/api/v1/flavor/3\",
        \"role_id\": \"spark-worker\"
      },
      {
        \"node_count\": 1,
        \"flavor\": \"/api/v1/flavor/3\",
        \"role_id\": \"notebook-server\"
      },
      {
        \"node_count\": 1,
        \"flavor\": \"/api/v1/flavor/3\",
        \"role_id\": \"livy-server\"
      }
    ],
    \"catalog_entry_distro_id\": \"${DISTRO_ID}\",
    \"config_choice_selections\": [],
    \"constraints\": []
  }
}
")

# TODO replace with a poll loop
sleep 300

# run actionscript as ad_admin1
grep 'username = ad_admin1' generated/hpecp.conf || echo 'username = ad_admin1' >> generated/hpecp.conf
grep 'password = pass123' generated/hpecp.conf || echo 'password = pass123' >> generated/hpecp.conf

CLUSTER_ID=$(PROFILE=tenant2 hpecp httpclient get  /api/v2/cluster/ |  jq -r "._embedded | .clusters | .[] | select(.label.name == \"${CLUSTER_NAME}\") | ._links.self.href")
PROFILE=tenant2 hpecp httpclient post ${CLUSTER_ID}/action_task <(echo "
{
  \"args\": \"\",
  \"label\": {
    \"name\":\"clone git repo\",
    \"description\":\"test\"
  },
  \"as_root\": \"false\",
  \"cmd\": \"#/bin/bash\n\nexport node=\$(bdvcli --get node.role_id)\nif [[ \$node == 'notebook-server' ]]; then\n   cd /home/ad_admin1\n   git clone https://github.com/snowch-notes/spark-py-notebooks\n   ls /home/ad_admin1\nfi\",
  \"nodegroupid\": \"1\" 
}
")

PROFILE=tenant2 hpecp httpclient post ${CLUSTER_ID}/action_task <(echo "
{
  \"args\": \"\",
  \"label\": {
    \"name\":\"install numpy and pandas 1\",
    \"description\":\"test\"
  },
  \"as_root\": \"false\",
  \"cmd\": \"#/bin/bash\n\nexport node=\$(bdvcli --get node.role_id)\nif [[ \$node != 'notebook-server' ]]; then\n   sudo /opt/python3.6/Python-3.6.5/python -m pip install numpy pandas\nfi\",
  \"nodegroupid\": \"1\" 
}
")

PROFILE=tenant2 hpecp httpclient post ${CLUSTER_ID}/action_task <(echo "
{
  \"args\": \"\",
  \"label\": {
    \"name\":\"install numpy and pandas 2\",
    \"description\":\"test\"
  },
  \"as_root\": \"false\",
  \"cmd\": \"#/bin/bash\nsudo /opt/jupyterhub/bin/pip install pandas numpy\",
  \"nodegroupid\": \"1\" 
}
")

