#!/bin/bash

set -e

source ./scripts/functions.sh

hpecp httpclient put /api/v1/workers/1 --json-file <(echo '{"operation": "schedule", "id": "/api/v1/workers/1", "schedule": true}')

echo "Request completed successfully"