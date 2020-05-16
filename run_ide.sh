#!/usr/bin/env bash

IMG=hpecp/hpecp-ide:latest

if [[ "$(docker images -q $IMG 2> /dev/null)" == "" ]]; then
  ./build_ide.sh
fi

docker run -it --init -p 3000:3000 -v "$(pwd):/home/project:cached" $IMG
