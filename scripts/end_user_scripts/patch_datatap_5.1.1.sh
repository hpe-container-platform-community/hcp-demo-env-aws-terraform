#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../variables.sh"

MAPR_BIN_DL_URL="$(aws s3 presign --region eu-west-1 s3://csnow-bins/libMapRClient_c.so.1)"
echo MAPR_BIN_DL_URL=$MAPR_BIN_DL_URL

for HOST in $CTRL_PUB_IP ${WRKR_PUB_IPS[@]}; 
do
	echo HOST=$HOST
	ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" centos@$HOST <<-SSH_EOF
		set -eux

		# if the host doesn't have bdconfig, it hasn't been added to HCP yet
		if command -v bdconfig >/dev/null 2>&1; then
			echo "Host ${HOST} has not been added to HCP yet - skipping  ..."

			sudo systemctl stop bds-worker

			# lrwxrwxrwx 1 root root        31 Aug 12 23:03 /usr/lib64/libMapRClient_c.so -> /usr/lib64/libMapRClient_c.so.1
			# -rw-r--r-- 1 root root 135860896 Jul 28 20:11 /usr/lib64/libMapRClient_c.so.1

			sudo rm -f /usr/lib64/libMapRClient_c.so

			curl "${MAPR_BIN_DL_URL}" > /home/centos/libMapRClient_c.so.1 

			sudo mv /home/centos/libMapRClient_c.so.1 /usr/lib64/libMapRClient_c.so.1
			sudo chown root:root /usr/lib64/libMapRClient_c.so.1
			sudo chmod 644 /usr/lib64/libMapRClient_c.so.1

			sudo ln -f -s /usr/lib64/libMapRClient_c.so.1 /usr/lib64/libMapRClient_c.so

			ls -al /usr/lib64/libMapRClient_c.so*

			sudo systemctl start bds-worker
		fi

	SSH_EOF
done