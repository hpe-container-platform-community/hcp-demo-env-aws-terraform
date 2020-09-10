#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Installing Spark23* catalog image"

CATALOG_IMAGES=$(hpecp catalog list --query "[? contains(label.name, 'Spark23')] | [?state!='installed' && state!='installing' && state!='verifying' && state!='downloading'] | [*].[_links.self.href] | []"  --output text)

for IMG_ID in $CATALOG_IMAGES
do
  echo "Installing: $IMG_ID"
  hpecp catalog install $IMG_ID
done

for i  in {1..1000}; do
  STATE=$(hpecp catalog list --query "[?_links.self.href=='/api/v1/catalog/3'] | [*].[state]" --output text)
  echo "State: $STATE"
  if [[ "$STATE" == "installed" ]]; then
    break
  else
    sleep 60
  fi
done
