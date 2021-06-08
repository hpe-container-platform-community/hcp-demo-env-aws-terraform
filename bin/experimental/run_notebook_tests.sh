#!/bin/bash 

set -o pipefail

if [[ -z $1 ]]; then
  echo Usage: $0 TENANT_ID
  exit 1
fi

set -u

./scripts/check_prerequisites.sh
source ./scripts/variables.sh
source ./scripts/functions.sh

print_header "Running script: $0 $@"

# use the project's HPECP CLI config file
export HPECP_CONFIG_FILE="./generated/hpecp.conf"

export TENANT_ID=$1
echo $TENANT_ID

export NB_CLUSTER_NAME=nb
echo NB_CLUSTER_NAME=$NB_CLUSTER_NAME

export MLFLOW_CLUSTER_NAME=mlflow
echo MLFLOW_CLUSTER_NAME=$MLFLOW_CLUSTER_NAME

export AD_USER_NAME=ad_user1
echo AD_USER_NAME=$AD_USER_NAME

export AD_USER_PASS=pass123
echo AD_USER_PASS=$AD_USER_PASS


export CLUSTER_ID=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [_links.k8scluster]" --output text)
echo CLUSTER_ID=$CLUSTER_ID

export TENANT_NS=$(hpecp tenant list --query "[?_links.self.href == '$TENANT_ID'] | [0] | [namespace]" --output text)
echo TENANT_NS=$TENANT_NS


set +o pipefail

ssh -q -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T ubuntu@${RDP_PUB_IP} <<-EOF1

    set -x

    POD=\$(kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
      get pod -l kubedirector.hpe.com/kdcluster=$NB_CLUSTER_NAME -n $TENANT_NS -o 'jsonpath={.items..metadata.name}')
      
      kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
        exec -c app -n $TENANT_NS \$POD \
        -- sudo -E -u ad_user1 /usr/bin/bash -c 'export PATH=\$PATH:/opt/miniconda/bin; /opt/miniconda/bin/pip3 install --quiet --user pytest nbval'
        
      THE_PATH=/opt/miniconda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/opt/bdfs:/opt/bluedata/hadoop-2.8.5/bin/:/home/ad_user1/.local/bin:/home/ad_user1/bin
      THE_JAVA_HOME=/etc/alternatives/jre

      kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
        exec -c app -n $TENANT_NS \$POD \
        -- sudo -E -u ad_user1 /usr/bin/bash -c  "export PATH=\$THE_PATH; export JAVA_HOME=\$THE_JAVA_HOME; pytest --nbval /home/ad_user1/datatap.ipynb"

      kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
        exec -c app -n $TENANT_NS \$POD \
        -- sudo -E -u ad_user1 /usr/bin/bash -c "export PATH=\$THE_PATH; export JAVA_HOME=\$THE_JAVA_HOME; pytest --nbval-lax /home/ad_user1/training-cluster-connection-test.ipynb"

      kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
        exec -c app -n $TENANT_NS \$POD \
        -- sudo -E -u ad_user1 /usr/bin/bash -c "export PATH=\$THE_PATH; export JAVA_HOME=\$THE_JAVA_HOME; pytest --nbval-lax /home/ad_user1/setLivy.ipynb"

      # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
      #  exec -c app -n $TENANT_NS \$POD \
      #  -- sudo -E -u ad_user1 /usr/bin/bash -c "export PATH=\$THE_PATH; export JAVA_HOME=\$THE_JAVA_HOME; pytest --nbval-lax /home/ad_user1/examples/model_explainability/lime_example.ipynb"

      # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
      #   exec -c app -n $TENANT_NS \$POD \
      #   -- sudo -E -u ad_user1 /usr/bin/bash -c "export PATH=\$THE_PATH; export JAVA_HOME=\$THE_JAVA_HOME; pytest --nbval-lax /home/ad_user1/examples/model_explainability/shap_example.ipynb"

      # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
      #   exec -c app -n $TENANT_NS \$POD \
      #   -- sudo -E -u ad_user1 /usr/bin/bash -c "export PATH=\$THE_PATH; export JAVA_HOME=\$THE_JAVA_HOME; pytest --nbval-lax /home/ad_user1/examples/model_explainability/shap_example_complete.ipynb"

      # kubectl --kubeconfig <(hpecp k8scluster --id $CLUSTER_ID admin-kube-config) \
      #   exec -c app -n $TENANT_NS \$POD \
      #   -- sudo -E -u ad_user1 /usr/bin/bash -c "export PATH=\$THE_PATH; export JAVA_HOME=\$THE_JAVA_HOME; pytest --nbval-lax /home/ad_user1/examples/spark/pyspark_example.ipynb"




EOF1
