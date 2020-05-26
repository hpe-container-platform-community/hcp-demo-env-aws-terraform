#!/usr/bin/env python3

from hpecp import ContainerPlatformClient
from hpecp.k8s_worker import WorkerK8sStatus
import os, sys, json

# Disable the SSL warnings - don't do this on productions!  
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

os.environ["LOG_LEVEL"] = "INFO"

try:
    with open('./generated/output.json') as f:
        j = json.load(f)
except: 
    print(80 * "*")
    print("ERROR: Can't parse: './generated/output.json'")
    print(80 * "*")
    sys.exit(1)

controller_public_ip  = j["controller_public_ip"]["value"]  
ad_server_private_ip  = j["ad_server_private_ip"]["value"]


client = ContainerPlatformClient(username='admin', 
                                password='admin123', 
                                api_host=controller_public_ip, 
                                api_port=8080,
                                use_ssl=True,
                                verify_ssl=False)
client.create_session()

worker_ids = []
for worker in client.k8s_worker.get_k8shosts():
    worker_id = worker.worker_id
    print("Found worker {} with state {}".format(worker_id, worker.status))
    client.k8s_worker.wait_for_status(worker_id=worker_id, timeout_secs=1200, status=[ WorkerK8sStatus.storage_pending ])
    data = {"op_spec": {"persistent_disks": ["/dev/nvme2n1"], "ephemeral_disks": ["/dev/nvme1n1"]}, "op": "storage"}
    client.k8s_worker.set_storage(worker_id=worker_id, data=data)
    worker_ids.append(worker_id)

# wait 20 minutes
for worker in worker_ids:
    print("Waiting 20 mins for worker id: {} to have status of ready".format(worker_id))
    client.k8s_worker.wait_for_status(worker_id=worker_id, timeout_secs=1200, status=[ WorkerK8sStatus.ready ])

print("Worker hosts are ready")
