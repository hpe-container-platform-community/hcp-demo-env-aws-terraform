#!/bin/bash

HIDE_WARNINGS=1

source "./scripts/variables.sh"

EDGE_HOST=$(printf $(terraform output -json mapr_cluster_2_hosts_public_ip_flat) | sed 's/"//' | head -n1)

echo "Dashboard url: http://${EDGE_HOST}:8080/dashboard/dashboardEdge.html"
echo "MCS url:       https://${EDGE_HOST}:8443"
