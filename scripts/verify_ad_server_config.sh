#!/usr/bin/env bash

# Ensure the AD server is correctly configured

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/variables.sh"

set +e
ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -tt -T centos@${CTRL_PUB_IP} <<-SSH_EOF

	set -x
	
	# Apply the posix classes ldif.  This should have been applied by terraform when the EC2 instance was created.
	# If it was applied, it will return 20 here.  If not, it will be run for the first time and return 0 if successful.	

	ssh -o StrictHostKeyChecking=no -tt -T centos@${AD_PRV_IP} \
		"ldapmodify -H ldap://localhost:389 -D 'cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com' -f /home/centos/ad_set_posix_classes.ldif -w '5ambaPwd@' -c 2>&1 > /dev/null"
SSH_EOF

ret_val=$?

# response code is 20 if the ldif has already been applied

if [[ "$ret_val" == "0" || "$ret_val" == "20" ]]; then
	echo "AD Server appears to be correctly configured."
else
	echo "Aborting. AD Server is not correctly configured."
	exit 1
fi

