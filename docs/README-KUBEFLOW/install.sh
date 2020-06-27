#!/bin/bash

set -e # abort on error
set -u # abort on underfined variable

export ISTIO_FILE=kfctl_hpc_istio.v1.0.1.yaml
export OPERATOR_BOOTSTRAP_FILE=operator_bootstrap.yaml
export TEST_LDAP_FILE=test_ldap.yaml
export CLUS_NAME="kubeflow_cluster"
export KUBECONFIG=./generated/${CLUS_NAME}.conf

check_prerequisites() {
	 if [[ ! -f $ISTIO_FILE ]]; then
			echo "Aborting. Can't find '$ISTIO_FILE' in '$(pwd)'"
			exit 1
	 fi
	 
	 if [[ ! -f $OPERATOR_BOOTSTRAP_FILE ]]; then
			echo "Aborting. Can't find '$OPERATOR_BOOTSTRAP_FILE' in '$(pwd)'"
			exit 1
	 fi
	 
	 if [[ ! -f $TEST_LDAP_FILE ]]; then
			echo "Aborting. Can't find '$TEST_LDAP_FILE' in '$(pwd)'"
			exit 1
	 fi
}

select_workers() {
	 # test the cli - should return your platform id
	 hpecp license platform-id 
	 
	 hpecp k8sworker list
	 # +-----------+--------+------------------------------------------+------------+---------------------------+
	 # | worker_id | status |                 hostname                 |   ipaddr   |           href            |
	 # +-----------+--------+------------------------------------------+------------+---------------------------+
	 # |    3      | ready  | ip-10-1-0-178.us-west-2.compute.internal | 10.1.0.178 | /api/v2/worker/k8shost/3  |
	 # |    4      | ready  | ip-10-1-0-93.us-west-2.compute.internal  | 10.1.0.93  | /api/v2/worker/k8shost/4  |
	 # +-----------+--------+------------------------------------------+------------+---------------------------+
	 
	 # get the HPE CP supported k8s 1.17.x version number
	 KVERS=$(hpecp k8scluster k8s-supported-versions --output text --major-filter 1 --minor-filter 17)
	 echo "Selecting K8S versoin: $KVERS"

	 K8S_READY_WORKER_ARRAY=($(hpecp k8sworker list --output json --query "[?status=='ready'].[_links.self.href]"  | tr -d '[],"'))
	 echo "Hosts in 'ready' state: '${K8S_READY_WORKER_ARRAY[@]}'"
	
	 NUM_READY_WORKERS=${#K8S_READY_WORKER_ARRAY[@]} 
	 if [[ $NUM_READY_WORKERS -lt 2 ]];  then
			echo "Aborting. At least two hosts with state of 'ready' are required. Found: $NUM_READY_WORKERS"
			exit 1
	 fi

	 # choose the first two ready hosts
	 MASTER_ID=${K8S_READY_WORKER_ARRAY[0]}
	 WORKER_ID=${K8S_READY_WORKER_ARRAY[1]}
	 MASTER_IP=$(hpecp k8sworker get ${MASTER_ID} | grep '^ipaddr' | cut -d " " -f 2)
	 MASTER_HOSTNAME=$(hpecp k8sworker get ${MASTER_ID} | grep '^hostname' | cut -d " " -f 2)
}

check_network_connectivity_to_master() {
	echo "Pinging master DNS address"
	ping -c 5 $MASTER_HOSTNAME || {
		echo "Aborting. Unable to ping Kubernetes Master: $MASTER_HOSTNAME - do you need to start the vpn?"
		exit 1
	}
}

create_cluster() {
	# create a K8s Cluster
	CLUS_ID=$(hpecp k8scluster create ${CLUS_NAME} ${MASTER_ID}:master,${WORKER_ID}:worker --k8s-version $KVERS)
	echo $CLUS_ID

	# wait until ready
	hpecp k8scluster wait-for-status $CLUS_ID --status "['ready']" --timeout-secs 1200

	# Setup the k8s cluster api-server
	ssh -o StrictHostKeyChecking=no -i "./generated/controller.prv_key" centos@${MASTER_IP} <<-END_SSH
		sudo sed -i '/^    - --service-account-key-file.*$/a\    - --service-account-issuer=kubernetes.default.svc' /etc/kubernetes/manifests/kube-apiserver.yaml
		sudo sed -i '/^    - --service-account-key-file.*$/a\    - --service-account-signing-key-file=\/etc\/kubernetes\/pki\/sa.key' /etc/kubernetes/manifests/kube-apiserver.yaml
	END_SSH

	# Give kube-apiserver a chance to restart
	sleep 60

	# Setup Kubectl
	hpecp k8scluster admin-kube-config ${CLUS_ID} > ${KUBECONFIG}
}

setup_kubeflow() {
	# Wait for api-server to restart and be ready
	#kubectl wait --for=condition=ready -l component=kube-apiserver -n kube-system pods --timeout 600s

	### Define PVs and apply the kubeflow scripts:

	# automatically create PVs
	kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
	kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
	kubectl patch storageclass default -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

	# Display the storage classes
	kubectl get sc

	### Deploy the Kubeflow operator

	# Apply the bootstrap script to deploy the operator: 
	kubectl apply -f $OPERATOR_BOOTSTRAP_FILE

	# need a better way to wait 
	sleep 300

	kubectl wait --for=condition=ready -l name=kubeflow-operator -n kubeflow-operator pods --timeout 600s

	### Now setup istio, etc.

	# Install the default services that are specified in 
	kubectl apply -f $ISTIO_FILE

	# need a better way to wait 
	sleep 300

	# Deploy the test LDAP service: 
	kubectl apply -f $TEST_LDAP_FILE

	### Configure AD/LDAP
	cat > ldap_configmap.yaml <<-EOF
	apiVersion: v1
	kind: ConfigMap
	metadata:
	  name: dex
	  namespace: auth
	data:
	  config.yaml: |
	    issuer: http://dex.auth.svc.cluster.local:5556/dex
	    storage:
	      type: kubernetes
	      config:
	        inCluster: true
	    web:
	      http: 0.0.0.0:5556
	    logger:
	      level: "debug"
	      format: text
	    oauth2:
	      skipApprovalScreen: true
	    enablePasswordDB: false
	    # staticPasswords:
	    #   - email: admin@kubeflow.org
	    #     hash: \$2y\$12\$ruoM7FqXrpVgaol44eRZW.4HWS8SAvg6KYVVSCIwKQPBmTpCm.EeO
	    #     username: admin
	    staticClients:
	      - id: kubeflow-oidc-authservice
	        redirectURIs: ["/login/oidc"]
	        name: 'Dex Login Application'
	        secret: pUBnBOY80SnXgjibTYM9ZWNzY2xreNGQok
	    connectors:
	    - type: ldap
	      id: ldap
	      name: LDAP
	      config:
	        host: $(terraform output ad_server_private_ip):636
	        insecureNoSSL: false
	        insecureSkipVerify: true
	        startTLS: false
	        bindDN: cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com
	        bindPW: 5ambaPwd@
	        usernamePrompt: username
	        userSearch:
	          baseDN: CN=Users,DC=samdom,DC=example,DC=com
	          filter: "(|(memberOf=CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com)(memberOf=CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com))"
	          username: cn
	          idAttr: cn
	          emailAttr: mail
	          nameAttr: givenName
	        groupSearch:
	          baseDN: CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com
	          filter: "(|(memberOf=CN=DemoTenantAdmins,CN=Users,DC=samdom,DC=example,DC=com)(memberOf=CN=DemoTenantUsers,CN=Users,DC=samdom,DC=example,DC=com))"
	          userAttr: DN
	          groupAttr: member
	          nameAttr: cn
	EOF
	kubectl apply -f ldap_configmap.yaml
	sleep 30

	kubectl rollout restart deployment dex -n auth
	sleep 300
}

## Debugging 
# kubectl logs -l app=dex -n auth -f


check_prerequisites
select_workers
check_network_connectivity_to_master
create_cluster
setup_kubeflow