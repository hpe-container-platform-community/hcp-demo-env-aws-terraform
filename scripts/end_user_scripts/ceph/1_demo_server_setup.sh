#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../variables.sh"

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" ubuntu@$RDP_PUB_IP <<-SSH_EOF
	sudo apt-get -qq install -y s3cmd

	PREV_ID=\$(docker ps -a | grep 'ceph/daemon' | awk '{ print \$1 }')
	echo PREV_ID=\$PREV_ID

	[[ "\$PREV_ID" ]] && docker stop "\$PREV_ID"
	[[ "\$PREV_ID" ]] && docker rm "\$PREV_ID"

	docker run -d --restart=always --privileged=true --name sandbox \
									-e MON_IP=$(terraform output rdp_server_private_ip) \
									-e CEPH_PUBLIC_NETWORK=$(terraform output subnet_cidr_block) \
									-e CEPH_DEMO_UID=sandboxId \
									-e CEPH_DEMO_ACCESS_KEY=sandboxAccessKey \
									-e CEPH_DEMO_SECRET_KEY=sandboxSecretKey \
									-e CEPH_DEMO_BUCKET=sandboxbucket \
									-e CEPH_DAEMON=DEMO \
									-e RGW_NAME=\$(hostname -f) \
									--net=host \
									ceph/daemon

	cat <<-EOF >~/.s3cfg
					[default]
					access_key = sandboxAccessKey
					access_token = 
					add_encoding_exts =
					add_headers =
					bucket_location = US
					ca_certs_file =
					cache_file =
					check_ssl_certificate = False
					check_ssl_hostname = False
					cloudfront_host = cloudfront.amazonaws.com
					default_mime_type = binary/octet-stream
					delay_updates = False
					delete_after = False
					delete_after_fetch = False
					delete_removed = False
					dry_run = False
					enable_multipart = True
					encoding = UTF-8
					encrypt = False
					expiry_date =
					expiry_days =
					expiry_prefix =
					follow_symlinks = False
					force = False
					get_continue = False
					gpg_command = /usr/bin/gpg
					gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
					gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
					gpg_passphrase =
					guess_mime_type = True
					host_base = \$(hostname -f):8080
					host_bucket = %(sandboxbucket).\$(hostname -f):8080
					human_readable_sizes = False
					invalidate_default_index_on_cf = False
					invalidate_default_index_root_on_cf = True
					invalidate_on_cf = False
					kms_key =
					limit = -1
					limitrate = 0
					list_md5 = False
					log_target_prefix =
					long_listing = False
					max_delete = -1
					mime_type =
					multipart_chunk_size_mb = 15
					multipart_max_chunks = 10000
					preserve_attrs = True
					progress_meter = True
					proxy_host =
					proxy_port = 0
					put_continue = False
					recursive = False
					recv_chunk = 65536
					reduced_redundancy = False
					requester_pays = False
					restore_days = 1
					restore_priority = Standard
					secret_key = sandboxSecretKey
					send_chunk = 65536
					server_side_encryption = False
					signature_v2 = False
					signurl_use_https = False
					simpledb_host = sdb.amazonaws.com
					skip_existing = False
					socket_timeout = 300
					stats = False
					stop_on_error = False
					storage_class =
					urlencoding_mode = normal
					use_http_expect = False
					use_https = False
					use_mime_magic = True
					verbosity = INFO
					website_endpoint = http://%(bucket)s.s3-website-%(location)s.amazonaws.com/
					website_error =
					website_index = index.html
	EOF

	# give ceph a chance to start
	sleep 30

	s3cmd ls

SSH_EOF