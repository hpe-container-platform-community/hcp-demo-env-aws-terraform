#!/bin/bash

if [[ ! -z $C9_USER && ( -z $AWS_ACCESS_KEY_ID || -z $AWS_SECRET_ACCESS_KEY ) ]];
then
    echo AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables must be set on Cloud 9
    exit 1
fi

. hpecp_env_conf.sh

CLUSTER_NAME=myeks
CLUSTER_DESC=myeks

terraform output eks-server-url > generated/eks_server_url

aws eks --region $(terraform output -raw aws_region) update-kubeconfig --name $(terraform output -raw eks-cluster-name) --kubeconfig generated/eks_kubeconfig &>/dev/null

kubectl --kubeconfig generated/eks_kubeconfig create serviceaccount abc123 &>/dev/null
kubectl --kubeconfig generated/eks_kubeconfig create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=default:abc123 &>/dev/null
SA_TOKEN=$(kubectl --kubeconfig generated/eks_kubeconfig get serviceaccount/abc123 -o jsonpath={.secrets[0].name})

set -e
set -u
set -o pipefail

kubectl --kubeconfig generated/eks_kubeconfig get secret $SA_TOKEN  -o jsonpath={'.data.token'} > generated/eks_token.base64
kubectl --kubeconfig generated/eks_kubeconfig get secret $SA_TOKEN  -o jsonpath={'.data.ca\.crt'} > generated/eks_ca.crt.base64

export POD_DNS_DOMAIN=cluster.local
export EKS_SERVER=$(cat generated/eks_server_url)
export EKS_CA_CERT=$(cat generated/eks_ca.crt.base64)
export EKS_TOKEN=$(cat generated/eks_token.base64)

set -x

hpecp k8scluster import-cluster \
    --cluster-type eks \
    --name $CLUSTER_NAME \
    --description $CLUSTER_DESC \
    --pod-dns-domain $POD_DNS_DOMAIN \
    --server-url $EKS_SERVER \
    --ca $EKS_CA_CERT \
    --bearer-token $EKS_TOKEN
    
    
watch hpecp k8scluster list
