#!/bin/bash

CATALOG_IMAGES=$(hpecp catalog list --query "[*].[_links.self.href] | []" | tr -d '"[],')
for IMG_ID in $CATALOG_IMAGES
do
  hpecp catalog install $IMG_ID
done
hpecp catalog list --query "[*].[_links.self.href,label.name,state]"
