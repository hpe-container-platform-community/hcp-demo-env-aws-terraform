#!/usr/bin/env python3

import os
import sys
import json

def parse_slice(value):
    """
    Parses a `slice()` from string, like `start:stop:step`.
    """
    if value:
        parts = value.split(':')
        if len(parts) == 1:
            # slice(stop)
            parts = [None, parts[0]]
        # else: slice(start, stop[, step])
    else:
        # slice()
        parts = []
    return slice(*[int(p) if p else None for p in parts])


KF_HOSTS_INDEX = parse_slice(sys.argv[1])


stream = os.popen("terraform output -json -no-color workers_private_ip")

obj=json.load(stream)



print('[' + ','.join('"{0}"'.format(w) for w in obj[0][KF_HOSTS_INDEX]) + ']')

