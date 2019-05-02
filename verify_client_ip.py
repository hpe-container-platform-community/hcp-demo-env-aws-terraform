#!/usr/bin/env python3

import ipaddress
import sys
import json
import urllib.request

declared_client_cidr_block = sys.argv[1]

check_client_ip = sys.argv[2]

if check_client_ip == 'true':

    with urllib.request.urlopen("http://ifconfig.me/ip") as response:
       actual_client_ip = response.read().decode('utf-8')

    if not ipaddress.IPv4Address(actual_client_ip) in ipaddress.IPv4Network(declared_client_cidr_block):
        raise Exception("ERROR: client_ip [{}] does not sit in client_cidr_block [{}]".format(actual_client_ip, declared_client_cidr_block))
    else:
      print(json.dumps({"ok": "true"}))

else:
    print(json.dumps({"ok": "true"}))
