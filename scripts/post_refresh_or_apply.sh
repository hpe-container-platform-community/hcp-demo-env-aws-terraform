#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/variables.sh"

cat >generated/hpecp.conf<<EOF
[default]
api_host = ${CTRL_PUB_IP}
api_port = 8080
use_ssl = ${INSTALL_WITH_SSL}
verify_ssl = False
warn_ssl = False
username = admin
password = admin123

[tenant2]
tenant = /api/v1/tenant/2
EOF

cat >generated/hpecp_private.conf<<EOF
[default]
api_host = ${CTRL_PRV_IP}
api_port = 8080
use_ssl = ${INSTALL_WITH_SSL}
verify_ssl = False
warn_ssl = False
username = admin
password = admin123

[tenant2]
tenant = /api/v1/tenant/2
EOF

cat >generated/get_admin_kubeconfig.sh<<EOF
#!/bin/bash

display_usage() { 
	echo -e "\nUsage: \$0 clustername\n" 
} 

if [[  \$# -lt 1 ]]; then
	display_usage
	exit 1
fi

CLUSTER_NAME=\$1
CLUSTER_ID=\$(hpecp k8scluster list --query "[?label.name == '\${CLUSTER_NAME}'] | [0] | [_links.self.href]" --output text)

CONF_FILE=$(mktemp)
hpecp k8scluster --id \$CLUSTER_ID admin-kube-config | sed s@https://.*:@https://${GATW_PUB_IP}:@
EOF

chmod +x generated/get_admin_kubeconfig.sh

# add private key to RDP server to allow passwordless ssh to all other hosts
if [[  "$RDP_SERVER_ENABLED" == "True" && "$RDP_SERVER_OPERATING_SYSTEM" = "LINUX" && "$RDP_PUB_IP" && -f generated/controller.prv_key ]]; then

	ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} "touch .hushlogin" 

    # We can leave the controller.prv_key in the home folder, because it is need when adding hosts to HCP
    cat generated/controller.prv_key | \
        ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} "cat > ~/.ssh/id_rsa" 

    ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} "chmod 600 ~/.ssh/id_rsa"

    cat generated/controller.prv_key | \
        ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} "cat > ~/Desktop/HCP_controller.prv_key" 

    cat generated/hpecp_private.conf | \
        ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} "cat > ~/.hpecp.conf"

    cat generated/get_admin_kubeconfig.sh | \
        ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} "cat > ~/get_admin_kubeconfig.sh"

	ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} "chmod +x ~/get_admin_kubeconfig.sh"


    #ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP}  "[[ -d .ssh ]] || mkdir -p ~/.ssh"
    #ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP}  "[[ -f .ssh/id_rsa ]] || mv ~/Desktop/controller.prv_key ~/.ssh/id_rsa && chmod 600 ~/.ssh/id_rsa"

	if [[  "$AD_SERVER_ENABLED" == "True" && "$AD_PUB_IP" ]]; then
		ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1    
			cat > ~/.ssh/config <<-EOF2
				Host controller
				HostName ${CTRL_PRV_IP}
				User centos
				StrictHostKeyChecking no

				Host gateway
				HostName ${GATW_PRV_IP}
				User centos
				StrictHostKeyChecking no

				Host ad
				HostName ${AD_PRV_IP}
				User centos
				StrictHostKeyChecking no
			EOF2
		EOF1
	fi

	ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF
		sudo cp /var/lib/snapd/desktop/applications/gedit_gedit.desktop /usr/share/applications/gedit.desktop
		xdg-mime default gedit.desktop text/plain
	EOF

	if [[ "$WORKER_COUNT" != "0" ]]; then
    	ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} "echo ${WRKR_PRV_IPS[@]} > ~/Desktop/HCP_WORKER_HOSTS.txt"
	fi

    # add private key to AD server to allow passwordless ssh to all other hosts
    if [[  "$AD_SERVER_ENABLED" == "True" && "$AD_PUB_IP" ]]; then
        cat generated/controller.pub_key | \
            ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${AD_PUB_IP} "cat >> /home/centos/.ssh/authorized_keys" 
    fi
fi

exit 0
