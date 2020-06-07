#!/bin/bash

kubectl delete -f kfctl_hpc_istio.v1.0.1.yaml

kubectl delete validatingwebhookconfigurations --all
kubectl delete mutatingwebhookconfigurations --all

kubectl apply -f kfctl_hpc_istio.v1.0.1.yaml

sleep 300

kubectl apply -f ldap_configmap.yaml

sleep 30

kubectl rollout restart deployment dex -n auth

sleep 300
