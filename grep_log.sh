#!/bin/bash

grep '| /api/v2/k8scluster/1 |  c1  |' 2021* | awk 'BEGIN { FS = "|" } ; { print $1, $6 }'

