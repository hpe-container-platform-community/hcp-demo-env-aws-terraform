#!/usr/bin/env bash

./bin/kubectl_as_admin.sh dfcluster exec admincli-0 -n dfdemo -- maprcli  acl edit -type  cluster -user ad_admin1:fc
./bin/kubectl_as_admin.sh dfcluster exec admincli-0 -n dfdemo -- maprcli  acl edit -type  cluster -user ad_user1:login