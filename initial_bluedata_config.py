#!/usr/bin/env python

import sys
import json
import requests
from bs4 import BeautifulSoup as bs4
from time import sleep

################################################################################
# http request/response logging
################################################################################

import logging

try:
    import http.client as http_client
except ImportError:
    # Python 2
    import httplib as http_client

# Uncomment the lines below to turn on debugging

# http_client.HTTPConnection.debuglevel = 1

# logging.basicConfig()
# logging.getLogger().setLevel(logging.DEBUG)
# requests_log = logging.getLogger("requests.packages.urllib3")
# requests_log.setLevel(logging.DEBUG)
# requests_log.propagate = True

################################################################################

client = requests.session()

URL='http://localhost/bdswebui/admininstall/'

r = client.get(URL)

html_bytes = r.text
soup = bs4(html_bytes, 'lxml')
csrf_token = soup.find('input', {'name':'csrfmiddlewaretoken'})['value'] 


headers = {}
headers['cookie'] = 'csrftoken=' + csrf_token
headers['Referer'] = 'http://localhost/bdswebui/admininstall/'
headers['content-type'] = 'application/x-www-form-urlencoded'
headers['X-CSRFToken'] = csrf_token
headers['X-Requested-With'] = 'XMLHttpRequest'

data = {
   "csrfmiddlewaretoken":      csrf_token,
   "float_startip":            "172.18.0.2",
   "float_endip":              "172.18.255.254",
   "float_mask":               "16",
   "int_gatewayip":            "172.18.0.1",
   "float_extif":              "ens3",
   "float_nexthop":            "172.18.0.1",
   "ispingreqd":               "on",
   "tenant_network_isolation": "on",
   "custom_install_name":      "",
   "bdshared_global_bdprefix": "bluedata-",
   "bdshared_global_bddomain": "bdlocal",
   "index_min":                "",
   "index_max":                "",
   "container_disks":          "/dev/xvdb",
   "shared_fs_type":           "default_hdfs",
   "hdfs_disks":               "/dev/xvdc",
   "local_kerberos_protected": "local_kerberized",
   "shared_fs_name":           "TenantStorage",
   "shared_fs_host":           "",
   "shared_fs_port":           "",
   "shared_fs_backup_host":    "",
   "shared_fs_container":      "",
   "shared_fs_path":           "",
   "kdc_host":                 "",
   "kdc_port":                 "",
   "keytab":                   "",
   "client_principal":         "",
   "service_id":               "",
   "realm":                    "",
   "username":                 "hdfs"
}


response = client.post('http://localhost/bdswebui/admininstall/', data=data, headers=headers)
#print(response.text)

def get_install_status():
    try:
       data = {"operation":"get_log", "csrfmiddlewaretoken":csrf_token}
       r = client.post('http://localhost/bdswebui/adminmanage/', data=json.dumps(data), headers=headers)
       return r.json()['install_progress']['install_state']
    except:
       return 'installing'

print('Starting BlueData initial configuration.')

while get_install_status() == 'installing':
    sys.stdout.write('.')
    sys.stdout.flush()
    if get_install_status() == 'installed':
        print (json.dumps({"ok": "true"}))
        print('Finished BlueData initial configuration.')
        sys.exit(0)
    sleep(30)

    # TODO add timeout to prevent never ending loop on error


