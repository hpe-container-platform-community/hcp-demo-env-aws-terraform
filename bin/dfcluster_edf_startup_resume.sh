#!/usr/bin/env bash

set -x

./bin/kubectl_as_admin.sh dfcluster exec admincli-0 -n dfdemo -- edf startup resume 