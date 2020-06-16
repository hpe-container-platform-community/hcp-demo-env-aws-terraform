#!/bin/bash

echo "Installing all catalog images - note that this script does NOT check for status=success."

CATALOG_IMAGES=$(hpecp catalog list --query "[*].[_links.self.href] | []" | tr -d '"[],')
for IMG_ID in $CATALOG_IMAGES
do
  hpecp catalog install $IMG_ID
done
hpecp catalog list --query "[*].[_links.self.href,label.name,state]"
