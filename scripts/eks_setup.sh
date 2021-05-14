#!/bin/bash


terraform output eks-server-url > generated/eks_server_url

aws eks --region $(terraform output -raw aws_region) update-kubeconfig --name $(terraform output -raw eks-cluster-name) --kubeconfig generated/eks_kubeconfig


kubectl --kubeconfig generated/eks_kubeconfig create serviceaccount abc123
kubectl --kubeconfig generated/eks_kubeconfig create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=default:abc123
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

bold=$(tput bold)
normal=$(tput sgr0)

echo
echo ${bold}export POD_DNS_DOMAIN${normal}=${POD_DNS_DOMAIN}
echo ${bold}export EKS_SERVER${normal}=${EKS_SERVER}
echo ${bold}export EKS_CA_CERT${normal}=${EKS_CA_CERT}
echo
echo ${bold}export EKS_TOKEN${normal}=${EKS_TOKEN}

echo
echo


#kubectl --kubeconfig generated/eks_kubeconfig describe configmaps/coredns  -n kube-system
