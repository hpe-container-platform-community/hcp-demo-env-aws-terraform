#!/usr/bin/env bash

./bin/kubectl_as_admin.sh dfcluster -n dfdemo get secret system -o yaml | grep MAPR_PASSWORD | head -1 | awk '{print $2}' | base64 --decode

echo
