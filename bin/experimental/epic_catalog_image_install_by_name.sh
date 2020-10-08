#!/bin/bash

if [[ $# != 1 ]]; then
   echo Usage: $0 IMAGE_NAME
   exit 1
fi

IMG_NAME="$1"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "Installing '${IMG_NAME}' catalog image"

CATALOG_IMAGES=$(hpecp catalog list --query "[? contains(label.name, '${IMG_NAME}')] | [?state!='installed' && state!='installing' && state!='verifying' && state!='downloading'] | [*].[_links.self.href] | []"  --output text)

if [[ ${#CATALOG_IMAGES[@]} == 0 ]]; then
  echo "'${IMG_NAME}' not found - exiting."
  exit 0
fi

for IMG_ID in $CATALOG_IMAGES
do
  echo "Installing: $IMG_ID"
  hpecp catalog install $IMG_ID

  for i  in {1..1000}; do
    STATE=$(hpecp catalog list --query "[?_links.self.href=='${IMG_ID}'] | [*].[state]" --output text)
    echo "State: $STATE"
    if [[ "$STATE" == "installed" ]]; then
      break
    else
      sleep 60
    fi
  done
done

