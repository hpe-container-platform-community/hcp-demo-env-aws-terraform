#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable
set -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/variables.sh"

echo "**************************************************************"
echo "* Select worker nodes that you would like to add to BlueData *"
echo "**************************************************************"

WRKR_PRV_IPS_TO_ADD=()
WRKR_PUB_IPS_TO_ADD=()

for INDEX in ${!WRKR_PUB_IPS[@]}; do 
  echo "Add the host ${WRKR_PUB_IPS[$INDEX]} (${WRKR_PRV_IPS[$INDEX]}) [y/n]? "
  read answer
  finish="-1"
  while [ "$finish" = '-1' ]
  do
    finish="1"
    if [ "$answer" = '' ];
    then
      answer=""
    else
      case $answer in
        y | Y | yes | YES ) answer="y";;
        n | N | no | NO ) answer="n";;
        *) finish="-1";
           echo 'Invalid response -- please reenter:';
           read answer;;
       esac
    fi
  done
  if [ $answer = "y" ]; 
  then
   WRKR_PRV_IPS_TO_ADD+=(${WRKR_PRV_IPS[$INDEX]})
   WRKR_PUB_IPS_TO_ADD+=(${WRKR_PUB_IPS[$INDEX]})
  fi
done

[ "${#WRKR_PRV_IPS_TO_ADD[@]}" == "0" ] && ( echo "WRKR_PRV_IPS_TO_ADD is empty - no workers to add.  Exiting..." && exit 1 )

echo WRKR_PRV_IPS_TO_ADD=${WRKR_PRV_IPS_TO_ADD[@]}
echo WRKR_PUB_IPS_TO_ADD=${WRKR_PUB_IPS_TO_ADD[@]}

###############################################################################
# Test SSH connectivity to EC2 instances from local machine
###############################################################################

for WRKR in ${WRKR_PUB_IPS_TO_ADD[@]}; do 
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} 'echo WORKER: $(hostname)'
done

###############################################################################
# Setup SSH keys for passwordless SSH
###############################################################################

# We have password SSH access from our local machines to EC2, so we can utiise this to copy the Controller SSH key to each Worker
for WRKR in ${WRKR_PUB_IPS_TO_ADD[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} "cat /home/centos/.ssh/id_rsa.pub" | \
        ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "cat >> /home/centos/.ssh/authorized_keys"
done

# test passwordless SSH connection from Controller to Workers
for WRKR in ${WRKR_PRV_IPS_TO_ADD[@]}; do 
    ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} << ENDSSH
        echo CONTROLLER: Connecting to WORKER ${WRKR}...
        ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa -T centos@${WRKR} "echo Connected!"
ENDSSH
done

###############################################################################
# Install RPMS
###############################################################################


for WRKR in ${WRKR_PUB_IPS_TO_ADD[@]}; do 
   if [[ "$SELINUX_DISABLED" == "True" ]];
   then
      echo "Disabling SELINUX on the worker host $WRKR"
      ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo sed -i --follow-symlinks 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux"
   fi
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo yum update -y -q"
   
   # install falco
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo yum-config-manager --enable repository cr"
   
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo rpm --import https://falco.org/repo/falcosecurity-3672BA8F.asc"
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo curl -s -o /etc/yum.repos.d/falcosecurity.repo https://falco.org/repo/falcosecurity-rpm.repo"

   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo yum -y install --enablerepo=extras epel-release"
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo yum -y install --enablerepo=epel dkms"
   
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo yum update -y -q"
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo yum -y install kernel*"
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "sudo yum -y install falco"
      
   # if the reboot causes ssh to terminate with an error, ignore it
   ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${WRKR} "nohup sudo reboot </dev/null &" || true
done

#
# Wait for Workers to come online after reboot
#

for WRKR in ${WRKR_PUB_IPS_TO_ADD[@]}; do 
    echo "Waiting for Worker ${WRKR} ssh session"
    while ! nc -w5 -z ${WRKR} 22; do printf "." -n ; done;
    echo 'Worker has rebooted'
done

cat << EOF


*********************************************************
*      BlueData worker setup completed successfully     *
*********************************************************

Now login to your BlueData deployment and navigate to th Installation tab:

   1. Add workers private ips "$(echo ${WRKR_PRV_IPS_TO_ADD[@]} | sed -e 's/ /,/g')"
   2. Upload generated/controller.prv_key
   3. Click Add hosts (enter site lock down when prompted)

   # After a few minutes, you should see Gateway 'Installed' and Workers 'Bundle completed'

   4. Select each Worker
   5. Click 'Install'
   6. Wait a few minutes


EOF

