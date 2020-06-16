#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

CATALOG_IMAGES=$(hpecp catalog list --query "[?state!='installed' && state!='installing' && state!='downloading'] | [*].[_links.self.href]" | tr -d '"[],')
for IMG_ID in $CATALOG_IMAGES
do
  echo "Installing: $IMG_ID"
  hpecp catalog install $IMG_ID
done

. ${SCRIPT_DIR}/epic_catalog_image_status.sh
