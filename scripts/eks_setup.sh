#!/bin/bash

terraform output eks-server-url > generated/eks_server_url

aws eks --region $(terraform output aws_region) update-kubeconfig --name $(terraform output eks-cluster-name) --kubeconfig generated/eks_kubeconfig

kubectl --kubeconfig generated/eks_kubeconfig create serviceaccount abc123
kubectl --kubeconfig generated/eks_kubeconfig create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=default:abc123

SA_TOKEN=$(kubectl --kubeconfig generated/eks_kubeconfig get serviceaccount/abc123 -o jsonpath={.secrets[0].name})

kubectl --kubeconfig generated/eks_kubeconfig get secret $SA_TOKEN  -o jsonpath={'.data.token'} > generated/eks_token.base64
kubectl --kubeconfig generated/eks_kubeconfig get secret $SA_TOKEN  -o jsonpath={'.data.ca\.crt'} > generated/eks_ca.crt.base64

bold=$(tput bold)
normal=$(tput sgr0)

echo
echo
echo ${bold}Pod DNS Domain${normal}: cluster.local
echo ${bold}EKS SERVER${normal}: $(cat generated/eks_server_url)
echo ${bold}EKS CA CERT${normal}:
cat generated/eks_ca.crt.base64
echo
echo ${bold}EKS TOKEN${normal}:
cat generated/eks_token.base64
echo
echo


#kubectl --kubeconfig generated/eks_kubeconfig describe configmaps/coredns  -n kube-system
