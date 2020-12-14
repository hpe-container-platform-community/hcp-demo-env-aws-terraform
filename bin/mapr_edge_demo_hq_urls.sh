#!/bin/bash

HIDE_WARNINGS=1

source "./scripts/variables.sh"

HQ_HOST=$(printf $(terraform output -json mapr_cluster_1_hosts_public_ip_flat) | sed 's/"//' | head -n1)

echo "Dashboard url: http://${HQ_HOST}:8080/dashboard/dashboardHQ.html"
echo "MCS url:       https://${HQ_HOST}:8443"
