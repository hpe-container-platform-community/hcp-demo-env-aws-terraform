#!/bin/bash 

set -e

./scripts/check_prerequisites.sh
source ./scripts/variables.sh

echo CLUSTER_ID=$CLUSTER_ID
echo NB_CLUSTER_NAME=$NB_CLUSTER_NAME
echo TENANT_NS=$TENANT_NS

cat static/mlflow/train.ipynb | ./bin/ssh_rdp_linux_server.sh "cat > train.ipynb"
cat static/mlflow/wine-quality.csv | ./bin/ssh_rdp_linux_server.sh "cat > wine-quality.csv"


ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

  set -e

  echo Waiting for Notebook to have state==configured
  
  COUNTER=0
  while [ \$COUNTER -lt 30 ]; 
  do
    STATE=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
                get kubedirectorcluster -n $TENANT_NS $NB_CLUSTER_NAME -o 'jsonpath={.status.state}')
    echo STATE=\$STATE
    [[ \$STATE == "configured" ]] && break
    sleep 1m
    let COUNTER=COUNTER+1 
  done

  # Retrieve the notebook pod

  POD=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    get pod -l kubedirector.hpe.com/kdcluster=$NB_CLUSTER_NAME -n $TENANT_NS -o 'jsonpath={.items..metadata.name}')
    
  echo TENANT_NS=$TENANT_NS
  echo POD=\$POD
  
  # Login to create home folders
  
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    exec -n $TENANT_NS \$POD -- sudo su - ad_admin1
    
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    exec -n $TENANT_NS \$POD -- sudo su - ad_user1
  
  # Copy example files to notebook pod  
  
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    cp train.ipynb $TENANT_NS/\$POD:/home/ad_admin1/train.ipynb
    
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    cp wine-quality.csv $TENANT_NS/\$POD:/home/ad_admin1/wine-quality.csv

  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    cp train.ipynb $TENANT_NS/\$POD:/home/ad_user1/train.ipynb
    
  kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
    cp wine-quality.csv $TENANT_NS/\$POD:/home/ad_user1/wine-quality.csv

EOF1
