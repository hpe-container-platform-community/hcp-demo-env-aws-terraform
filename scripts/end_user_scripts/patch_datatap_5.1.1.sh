#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../variables.sh"

MAPR_BIN_DL_URL="$(aws s3 presign --region eu-west-1 s3://csnow-bins/libMapRClient_c.so.1)"
echo MAPR_BIN_DL_URL=$MAPR_BIN_DL_URL

for HOST in $CTRL_PUB_IP ${WRKR_PUB_IPS[@]}; 
do
	echo HOST=$HOST
	ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" centos@$HOST <<-SSH_EOF
		set -eu

		# if the host has bdconfig, it has been added to HCP
		if command -v bdconfig >/dev/null 2>&1; then

			# now select the controller and worker hosts
			EPIC_HOSTS=\$(bdconfig  --getworkers | awk '{ if (\$5 != "proxy") { print \$2 }  }')
			CURR_HOST=\$(hostname -I | awk '{ print \$1 }')

			# Only run on EPIC hosts and not K8S hosts
			if [[ \${EPIC_HOSTS} == *"\${CURR_HOST}"* ]]; then

				echo "Patching DataTap on EPIC Host ${HOST} (\${CURR_HOST}) ..."

				sudo systemctl stop bds-worker

				sudo rm -f /usr/lib64/libMapRClient_c.so

				curl -s "${MAPR_BIN_DL_URL}" > /home/centos/libMapRClient_c.so.1 

				sudo mv /home/centos/libMapRClient_c.so.1 /usr/lib64/libMapRClient_c.so.1
				sudo chown root:root /usr/lib64/libMapRClient_c.so.1
				sudo chmod 644 /usr/lib64/libMapRClient_c.so.1

				sudo ln -f -s /usr/lib64/libMapRClient_c.so.1 /usr/lib64/libMapRClient_c.so

				ls -al /usr/lib64/libMapRClient_c.so*

				sudo systemctl start bds-worker
			else
				echo "Skipping Host ${HOST} ..."
			fi
		else
			echo "Skipping Host ${HOST} ..."
		fi

	SSH_EOF
done
