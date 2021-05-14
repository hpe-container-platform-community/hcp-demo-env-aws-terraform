#!/bin/bash


. hpecp_env_conf.sh

CLUSTER_NAME=myeks
CLUSTER_DESC=myeks

hpecp k8scluster import-cluster eks $CLUSTER_NAME $CLUSTER_DESC $POD_DNS_DOMAIN $EKS_SERVER $EKS_CA_CERT $EKS_TOKEN
