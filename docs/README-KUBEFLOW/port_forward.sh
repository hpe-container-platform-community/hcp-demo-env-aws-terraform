#!/bin/bash

export KUBECONFIG=./generated/kubeflow_cluster.conf
export NAMESPACE=istio-system
kubectl port-forward -n ${NAMESPACE} svc/istio-ingressgateway 8080:80
