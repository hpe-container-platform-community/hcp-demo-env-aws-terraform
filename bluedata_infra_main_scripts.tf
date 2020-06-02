
resource "local_file" "ca-cert" {
  filename = "${path.module}/generated/ca-cert.pem"
  content =  var.ca_cert
}

resource "local_file" "ca-key" {
  filename = "${path.module}/generated/ca-key.pem"
  content =  var.ca_key
}


//////////////////// Utility scripts  /////////////////////

/// instance start/stop/status

locals {
  instance_ids = "${module.nfs_server.instance_id != null ? module.nfs_server.instance_id : ""} ${module.ad_server.instance_id != null ? module.ad_server.instance_id : ""} ${module.rdp_server.instance_id != null ? module.rdp_server.instance_id : ""} ${module.rdp_server_linux.instance_id != null ? module.rdp_server_linux.instance_id : ""} ${module.controller.id} ${module.gateway.id} ${join(" ", aws_instance.workers.*.id)}"
}

resource "local_file" "cli_stop_ec2_instances" {
  filename = "${path.module}/generated/cli_stop_ec2_instances.sh"
  content =  <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"

    SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=1 -q"
    CMD='nohup sudo halt -n </dev/null &'

    echo "Sending 'sudo halt -n' to all hosts for graceful shutdown."

    if [[ -z WRKR_PUB_IPS ]]; then
       for HOST in $${WRKR_PUB_IPS[@]}; do
         ssh $SSH_OPTS -i "${var.ssh_prv_key_path}" centos@$HOST "$CMD" || true
       done
    fi

    ssh $SSH_OPTS -i "${var.ssh_prv_key_path}" centos@$GATW_PUB_IP "$CMD" || true
    ssh $SSH_OPTS -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP "$CMD" || true

    echo "Sleeping 120s allowing halt to complete before issuing 'ec2 stop-instances' command"
    sleep 120

    echo "Stopping instances"
    aws --region ${var.region} --profile ${var.profile} ec2 stop-instances \
        --instance-ids ${local.instance_ids} \
        --output table \
        --query "StoppingInstances[*].{ID:InstanceId,State:CurrentState.Name}"
  EOF
}

resource "local_file" "cli_start_ec2_instances" {
  filename = "${path.module}/generated/cli_start_ec2_instances.sh"
  content = <<-EOF
    #!/bin/bash

    OUTPUT_JSON=$(cat "${path.module}/generated/output.json")

    CLIENT_CIDR_BLOCK=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["client_cidr_block"]["value"])')
    [ "$CLIENT_CIDR_BLOCK" ] || ( echo "ERROR: CLIENT_CIDR_BLOCK is empty" && exit 1 )

    aws --region ${var.region} --profile ${var.profile} ec2 start-instances \
        --instance-ids ${local.instance_ids} \
        --output table \
        --query "StartingInstances[*].{ID:InstanceId,State:CurrentState.Name}"

    CURR_CLIENT_CIDR_BLOCK="$(curl -s http://ifconfig.me/ip)/32"

    # check if the client IP address has changed
    if [[ "$CLIENT_CIDR_BLOCK" = "$CURR_CLIENT_CIDR_BLOCK" ]]; then
      UPDATE_COMMAND="refresh"
    else
      UPDATE_COMMAND="apply"
    fi

    echo "***********************************************************************************************************"
    echo "IMPORTANT: You need to run the following command to update your local state:"
    echo
    echo "           ./bin/terraform_$UPDATE_COMMAND.sh"
    echo 
    echo "           If you encounter an error running ./bin/terraform_$UPDATE_COMMAND.sh it is probably because your"
    echo "           instances are not ready yet.  You can check the instances status with:"
    echo 
    echo "           ./generated/cli_running_ec2_instances.sh"
    echo "***********************************************************************************************************"
  EOF
}


resource "local_file" "cli_running_ec2_instances" {
  filename = "${path.module}/generated/cli_running_ec2_instances.sh"
  content = <<-EOF
    #!/bin/bash
    aws --region ${var.region} --profile ${var.profile} ec2 describe-instances \
      --instance-ids ${local.instance_ids} \
      --output table \
      --query "Reservations[*].Instances[*].{ExtIP:PublicIpAddress,IntIP:PrivateIpAddress,ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key=='Name']|[0].Value}"
  EOF  
}


resource "local_file" "cli_running_ec2_instances_all_regions" {
  filename = "${path.module}/generated/cli_running_ec2_instances_all_regions.sh"
  content = <<-EOF
    #!/bin/bash
    export AWS_DEFAULT_REGION=${var.region}
    for region in `aws ec2 describe-regions --output text | cut -f4`; do
      echo -e "\nListing Running Instances in region:'$region' ... matching '${var.user}' ";
      aws ec2 describe-instances --query "Reservations[*].Instances[*].{IP:PublicIpAddress,ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[0].Value}" --filters Name=instance-state-name,Values=running --output=table --region $region | grep -i ${var.user}
    done
  EOF  
}

resource "local_file" "ssh_controller_port_forwards" {
  filename = "${path.module}/generated/ssh_controller_port_forwards.sh"
  content = <<-EOF
    #!/bin/bash

    source "${path.module}/scripts/variables.sh"

    if [[ -e "${path.module}/etc/port_forwards.sh" ]]
    then
      PORT_FORWARDS=$(cat "${path.module}/etc/port_forwards.sh")
    else
      echo ./etc/port_forwards.sh file not found please create it and add your rules, e.g.
      echo cp ./etc/port_forwards.sh_template ./etc/port_forwards.sh
      exit 1
    fi
    echo Creating port forwards from "${path.module}/etc/port_forwards.sh"

    set -x
    ssh -o StrictHostKeyChecking=no \
      -i "${var.ssh_prv_key_path}" \
      -N \
      centos@$CTRL_PUB_IP \
      $PORT_FORWARDS \
      "$@"
  EOF
}

resource "local_file" "ssh_controller" {
  filename = "${path.module}/generated/ssh_controller.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP "$@"
  EOF
}

resource "local_file" "ssh_controller_private" {
  filename = "${path.module}/generated/ssh_controller_private.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$CTRL_PRV_IP "$@"
  EOF
}

resource "local_file" "ssh_gateway" {
  filename = "${path.module}/generated/ssh_gateway.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP "$@"
  EOF
}

resource "local_file" "ssh_worker" {
  count = var.worker_count

  filename = "${path.module}/generated/ssh_worker_${count.index + 1}.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$${WRKR_PUB_IPS[${count.index}]} "$@"
  EOF
}

resource "local_file" "ssh_workers" {
  count = var.worker_count
  filename = "${path.module}/generated/ssh_worker_all.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     if [[ $# -lt 1 ]]
     then
        echo "You must provide at least one command, e.g."
        echo "./generated/ssh_worker_all.sh CMD1 CMD2 CMDn"
        exit 1
     fi

     for HOST in $${WRKR_PUB_IPS[@]}; 
     do
      ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$HOST "$@"
     done
  EOF
}

resource "local_file" "ssh_all" {
  count = var.worker_count
  filename = "${path.module}/generated/ssh_all.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     if [[ $# -lt 1 ]]
     then
        echo "You must provide at least one command, e.g."
        echo "./generated/ssh_worker_all.sh CMD1 CMD2 CMDn"
        exit 1
     fi

     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP "$@"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$GATW_PUB_IP "$@"
     for HOST in $${WRKR_PUB_IPS[@]};
     do
        ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$HOST "$@"
     done
  EOF
}

resource "local_file" "mcs_credentials" {
  filename = "${path.module}/generated/mcs_credentials.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     echo 
     echo ==== MCS Credentials ====
     echo 
     echo IP Addr:  $CTRL_PUB_IP
     echo Username: admin
     echo Password: $(ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP "cat /opt/bluedata/mapr/conf/mapr-admin-pass")
     echo
  EOF
}

resource "local_file" "fix_restart_auth_proxy" {
  filename = "${path.module}/generated/fix_restart_auth_proxy.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP 'docker restart $(docker ps | grep "epic/authproxy" | cut -d " " -f1); docker ps'
  EOF
}

resource "local_file" "fix_restart_webhdfs" {
  filename = "${path.module}/generated/fix_restart_webhdfs.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP 'docker restart $(docker ps | grep "epic/webhdfs" | cut -d " " -f1); docker ps'
  EOF
}

resource "local_file" "platform_id" {
  filename = "${path.module}/generated/platform_id.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     curl -s -k https://$CTRL_PUB_IP:8080/api/v1/license | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["uuid"])'
  EOF
}

resource "local_file" "rdp_windows_credentials" {
  filename = "${path.module}/generated/rdp_credentials.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "WINDOWS" ? 1 : 0
  content = <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"

    if grep -q 'OPENSSH' "${var.ssh_prv_key_path}"
    then
      echo "***** ERROR ******"
      echo "Found OPENSSH key but need RSA key at ${var.ssh_prv_key_path}"
      echo "You can convert with:"
      echo "$ ssh-keygen -p -N '' -m pem -f '${var.ssh_prv_key_path}'"
      echo "******************"
      exit 1
    fi

    echo 
    echo ==== RDP Credentials ====
    echo 
    echo IP Addr:  ${module.rdp_server.public_ip}
    echo URL:      "rdp://full%20address=s:${module.rdp_server.public_ip}:3389&username=s:Administrator"
    echo Username: Administrator
    echo -n "Password: "
    aws --region ${var.region} \
        --profile ${var.profile} \
        ec2 get-password-data \
        "--instance-id=${module.rdp_server.instance_id}" \
        --query 'PasswordData' | sed 's/\"\\r\\n//' | sed 's/\\r\\n\"//' | base64 -D | openssl rsautl -inkey "${var.ssh_prv_key_path}" -decrypt
    echo
    echo
  EOF
}

resource "local_file" "rdp_linux_credentials" {
  filename = "${path.module}/generated/rdp_credentials.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content = <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"
    echo 
    echo ================================= RDP Credentials  =====================================
    echo 
    if [[ "$CREATE_EIP_RDP_LINUX_SERVER" == "False" ]]; then
    echo Note: The RDP IP addresses listed below change each time the RDP instance is restarted.
    else
    echo Note: The RDP IP addresses listed below are provided by an EIP and are static.
    fi
    echo
    echo Host IP:   "$RDP_PUB_IP"
    echo Web Url:   "https://$RDP_PUB_IP (Chrome is recommended)"
    echo RDP URL:   "rdp://full%20address=s:$RDP_PUB_IP:3389&username=s:ubuntu"
    echo Username:  "ubuntu"
    echo Password:  "$RDP_INSTANCE_ID"
    echo 
    echo ========================================================================================
    echo
  EOF
}

resource "local_file" "rdp_over_ssh" {
  filename = "${path.module}/generated/rdp_over_ssh.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content = <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"
    echo "Portforwarding 3389 on 127.0.0.1 to RDP Server [CTRL-C to cancel]"
    ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" ubuntu@$RDP_PUB_IP "$@" -L3389:localhost:3389 -N
  EOF
}

resource "local_file" "rdp_post_setup" {
  filename = "${path.module}/generated/rdp_post_provision_setup.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content = <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"
    ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" ubuntu@$RDP_PUB_IP "sudo fastdd"  
  EOF
}

resource "local_file" "ssh_rdp_linux" {
  filename = "${path.module}/generated/ssh_rdp_linux_server.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content = <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"
    ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" ubuntu@$RDP_PUB_IP "$@"    
  EOF
}

resource "local_file" "sftp_rdp_linux" {
  filename = "${path.module}/generated/sftp_rdp_linux_server.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content = <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"
    sftp -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" ubuntu@$RDP_PUB_IP    
  EOF
}

resource "local_file" "whatismyip" {
  filename = "${path.module}/generated/whatismyip.sh"

  content = <<-EOF
     #!/bin/bash
     echo $(curl -s http://ifconfig.me/ip)/32
  EOF
}

resource "local_file" "vpn_server_setup" {
  filename = "${path.module}/generated/vpn_server_setup.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content  = <<-EOF
    #!/bin/bash

    set -e # abort on error
    set -u # abort on undefined variable

    source "${path.module}/scripts/variables.sh"

    if [[ ! -f "${path.module}/generated/vpn_users" ]]; then
        echo user1:$(openssl rand -hex 12 | tr -d '\n') > "${path.module}/generated/vpn_users"
        echo $(openssl rand -hex 30 | tr -d '\n') > "${path.module}/generated/vpn_shared_key"
    fi

    VPN_USERS=$(cat "${path.module}/generated/vpn_users")
    VPN_PSK=$(cat "${path.module}/generated/vpn_shared_key")

    ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" ubuntu@$RDP_PUB_IP <<-SSH_EOF
      set -eux
      sudo ufw allow 1701
      if docker ps | grep softethervpn; then
        docker kill \$(docker ps | grep softethervpn | awk '{ print \$1 }')
      fi
      docker run -d --cap-add NET_ADMIN --restart=always -e USERS="$VPN_USERS" -e PSK="$VPN_PSK" -p 500:500/udp -p 4500:4500/udp -p 1701:1701/tcp -p 1194:1194/udp -p 5555:5555/tcp siomiz/softethervpn
    SSH_EOF
  EOF
}

resource "local_file" "vpn_mac_connect" {
  filename = "${path.module}/generated/vpn_mac_connect.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content  = <<-EOF
    #!/bin/bash

    set -e # abort on error
    set -u # abort on undefined variable

    source "${path.module}/scripts/variables.sh"
  
    if [[ "$EUID" != "0" ]]; then
      echo "This script must be run as root - e.g. with sudo" 
      exit 1
    fi

    USER_BEFORE_SUDO=$(who am i | awk '{print $1}')

    if [[ ! -f "${path.module}/generated/vpn_users" ]]; then
        echo "ERROR: '${path.module}/generated/vpn_users' not found - have you run '${path.module}/generated/vpn_server_setup.sh'?"
        exit 1
    fi

    VPN_USERS=$(sudo -u $USER_BEFORE_SUDO cat "${path.module}/generated/vpn_users")
    VPN_PSK=$(sudo -u $USER_BEFORE_SUDO cat "${path.module}/generated/vpn_shared_key")

    if ! sudo -u $USER_BEFORE_SUDO command -v macosvpn >/dev/null 2>&1; then 
      echo "'macosvpn' is required but it's not installed.  You can install it with 'brew install macosvpn'.  Aborting.";
      exit 1
    fi

    VPN_USER=$(echo $VPN_USERS | cut -d ":" -f1)
    VPN_PASS=$(echo $VPN_USERS | cut -d ":" -f2)

    macosvpn create --l2tp hpe-container-platform-aws \
                            --force \
                            --endpoint $(terraform output rdp_server_public_ip) \
                            --username $VPN_USER \
                            --password $VPN_PASS \
                            --sharedsecret $VPN_PSK \
                            --split # Do not send all traffic across VPN tunnel

    echo "Waiting 10s for vpn settings to save"
    sleep 10
    sudo -u $USER_BEFORE_SUDO /usr/sbin/networksetup -connectpppoeservice "hpe-container-platform-aws"
    
    echo "Waiting 10s for VPN to start"
    sleep 10

    # VPN Status
    scutil --nc list | grep hpe-container-platform-aws

    route -n delete -net $(terraform output subnet_cidr_block) $(terraform output softether_rdp_ip) || true # ignore error
    route -n add -net $(terraform output subnet_cidr_block) $(terraform output softether_rdp_ip)

    # VPC DNS Server is base of VPC network range plus 2 - https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html
    VPC_DNS_SERVER=$(python3 -c "import ipcalc; print(str((ipcalc.Network('$VPC_CIDR_BLOCK')+2)).split('/')[0])")
    networksetup -setdnsservers hpe-container-platform-aws $VPC_DNS_SERVER
    echo "VPN DNS set to: $(networksetup -getdnsservers hpe-container-platform-aws)"

    echo "Looking up controller private dns with dig"
    dig @$VPC_DNS_SERVER $(terraform output controller_private_dns)

    echo "Attempting to ping the controller private IP ..."
    ping -c 5 $CTRL_PRV_IP

    echo "******************************************************************************"
    echo "                                 IMPORTANT"
    echo "******************************************************************************"
    if [[ "$CREATE_EIP_RDP_LINUX_SERVER" == "False" ]]; then
    echo "- You need to run this script every time you restart your instances to update"
    echo "  the VPN with the RDP server new public IP address."
    else
    echo "- You are using a EIP for the RDP server, you can connect/disconnect the vpn"
    echo "  using the tools provided with your OS."
    fi
    echo "*****************************************************************************"
  EOF
}

resource "local_file" "vpn_mac_delete" {
  filename = "${path.module}/generated/vpn_mac_delete.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content  = <<-EOF
    #!/bin/bash

    set -e # abort on error
    set -u # abort on undefined variable

    source "${path.module}/scripts/variables.sh"
  
    if [[ "$EUID" != "0" ]]; then
      echo "This script must be run as root - e.g. with sudo" 
      exit 1
    fi

    macosvpn delete --name hpe-container-platform-aws || true # ignore error
    route -n delete -net $(terraform output subnet_cidr_block) $(terraform output softether_rdp_ip) || true # ignore error
  EOF
}

resource "local_file" "vpn_mac_status" {
  filename = "${path.module}/generated/vpn_mac_status.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content  = <<-EOF
    #!/bin/bash

    set -e # abort on error
    set -u # abort on undefined variable

    source "${path.module}/scripts/variables.sh"
  
    if [[ "$EUID" != "0" ]]; then
      echo "This script must be run as root - e.g. with sudo" 
      exit 1
    fi

    VPN_STATUS="'$(scutil --nc list | grep hpe-container-platform-aws)'"
    if [[ "$VPN_STATUS" == "''" ]]; then
      echo "VPN not found."
    else
      echo "$VPN_STATUS"
    fi
  EOF
}

resource "local_file" "get_public_endpoints" {
  filename = "${path.module}/generated/get_public_endpoints.sh"
  content  = <<-EOF
    #!/usr/bin/env python3

    import json,sys,subprocess

    try:
      with open('${path.module}/generated/output.json') as f:
          j = json.load(f)
    except: 
      print(80 * "*")
      print("ERROR: Can't parse: '${path.module}/generated/output.json'")
      print(80 * "*")
      sys.exit(1)

    try:
        rdp_server_public_ip  = j["rdp_server_public_ip"]["value"]
        rdp_server_public_dns = "NA"
        rdp_server_eip        = j["create_eip_rdp_linux_server"]["value"]
    except:
        rdp_server_public_ip  = "NA"
        rdp_server_public_dns = "NA"
        rdp_server_eip        = "NA"

    controller_public_ip  = j["controller_public_ip"]["value"]
    controller_public_dns = j["controller_public_dns"]["value"]
    controller_eip        = j["create_eip_controller"]["value"]

    gateway_public_ip     = j["gateway_public_ip"]["value"]
    gateway_public_dns    = j["gateway_public_dns"]["value"]
    gateway_eip           = j["create_eip_gateway"]["value"]

    workers_public_ips    = j["workers_public_ip"]["value"][0]
    workers_public_dns    = j["workers_public_dns"]["value"][0]

    print('------------  ----------------  --------------------------------------------------------  -----')
    print('{:>12}  {:>16}  {:>56}  {:>5}'.format( "NAME", "IP", "DNS", "EIP?"))
    print('------------  ----------------  --------------------------------------------------------  -----')
    print('{:>12}  {:>16}  {:>56}  {:>5}'.format( "RDP Server", rdp_server_public_ip, rdp_server_public_dns, rdp_server_eip))
    print('{:>12}  {:>16}  {:>56}  {:>5}'.format( "Controller", controller_public_ip, controller_public_dns, controller_eip))
    print('{:>12}  {:>16}  {:>56}  {:>5}'.format( "Gateway",    gateway_public_ip,    gateway_public_dns,    gateway_eip))

    for num, ip in enumerate(workers_public_ips):
       print('{:>9}{:>3}  {:>16}  {:>56}  {:>5}'.format( "Worker", num, ip, workers_public_dns[num], "NA"))
    print('------------  ----------------  --------------------------------------------------------  -----')
  EOF
}

resource "local_file" "get_private_endpoints" {
  filename = "${path.module}/generated/get_private_endpoints.sh"
  content  = <<-EOF
    #!/usr/bin/env python3

    import json,sys,subprocess

    try:
      with open('${path.module}/generated/output.json') as f:
          j = json.load(f)
    except: 
      print(80 * "*")
      print("ERROR: Can't parse: '${path.module}/generated/output.json'")
      print(80 * "*")
      sys.exit(1)

    try:
        rdp_server_private_ip  = j["rdp_server_private_ip"]["value"]
        rdp_server_private_dns = "NA"
    except:
        rdp_server_private_ip  = "NA"
        rdp_server_private_dns = "NA"

    controller_private_ip  = j["controller_private_ip"]["value"]
    controller_private_dns = j["controller_private_dns"]["value"]

    gateway_private_ip     = j["gateway_private_ip"]["value"]
    gateway_private_dns    = j["gateway_private_dns"]["value"]

    workers_private_ips    = j["workers_private_ip"]["value"][0]
    workers_private_dns    = j["workers_private_dns"]["value"][0]

    try:
        ad_server_private_ip  = j["ad_server_private_ip"]["value"]
        ad_server_private_dns = "NA"
    except:
        ad_server_private_ip  = "NA"
        ad_server_private_dns = "NA"

    print('------------  ----------------  --------------------------------------------------------')
    print('{:>12}  {:>16}  {:>56}'.format( "NAME", "IP", "DNS"))
    print('------------  ----------------  --------------------------------------------------------')
    print('{:>12}  {:>16}  {:>56}'.format( "RDP Server", rdp_server_private_ip, rdp_server_private_dns))
    print('{:>12}  {:>16}  {:>56}'.format( "Controller", controller_private_ip, controller_private_dns))
    print('{:>12}  {:>16}  {:>56}'.format( "Gateway",    gateway_private_ip,    gateway_private_dns))
    print('{:>12}  {:>16}  {:>56}'.format( "AD",         ad_server_private_ip,  ad_server_private_dns))

    for num, ip in enumerate(workers_private_ips):
       print('{:>9}{:>3}  {:>16}  {:>56}'.format( "Worker", num, ip, workers_private_dns[num]))
    print('------------  ----------------  --------------------------------------------------------')
  EOF
}
