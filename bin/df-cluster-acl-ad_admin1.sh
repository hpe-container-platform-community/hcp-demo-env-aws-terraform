#!/bin/bash

set -x

./generated/ssh_controller.sh bdmapr maprcli acl edit -type  cluster -user ad_admin1:fc
