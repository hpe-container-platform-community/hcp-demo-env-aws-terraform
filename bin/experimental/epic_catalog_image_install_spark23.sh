#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Installing Spark23* catalog images - note that this script does NOT check for status=success."

CATALOG_IMAGES=$(hpecp catalog list --query "[? contains(label.name, 'Spark23')] | [?state!='installed' && state!='installing' && state!='verifying' && state!='downloading'] | [*].[_links.self.href] | []"  --output text)

for IMG_ID in $CATALOG_IMAGES
do
  echo "Installing: $IMG_ID"
  hpecp catalog install $IMG_ID
done

. ${SCRIPT_DIR}/epic_catalog_image_status.sh
