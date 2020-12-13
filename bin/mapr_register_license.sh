#!/bin/bash

set -e # abort on error
set -u # abort on undefined variable

source "./scripts/variables.sh"
source "./scripts/functions.sh"

################################################################################ 
print_header "Register License"
################################################################################ 

echo
echo "Enter credentials for mapr.com."
echo

echo -n "Username: "
read username
echo -n "Password: "
read -s password


if [[ "$MAPR_CLUSTER1_COUNT" != "0" ]]; then

   ./generated/ssh_mapr_cluster_1_host_0.sh sudo apt-get install -y jq

   ./generated/ssh_mapr_cluster_1_host_0.sh <<EOF

      CLUSTERID=\$(maprcli license showid -cluster $MAPR_CLUSTER1_NAME | tail -1 | tr -d ' ')

      URL="https://mapr-installer-dialhome.appspot.com/trial?"
      URL+="cluster_name=$MAPR_CLUSTER1_NAME"
      URL+="&cluster_id=\$CLUSTERID"
      URL+="&maprcom_username=\$(echo $username | perl -ne 'chomp and print' | base64)"
      URL+="&maprcom_password=\$(echo $password | perl -ne 'chomp and print' | base64)"

      echo \$URL

      curl -s \$URL \
         | jq ".data.cluster.licenses[0].key_contents" \
         | sed 's!^"!!g' \
         | sed 's!"\$!!g' \
         | sed 's!\\\\"!"!g' \
         > license.txt
         
      perl -pe 's/\\\\n/\\n/g' license.txt > license2.txt
      perl -pe 's/\\\\r/\\r/g' license2.txt > license3.txt

      maprcli license add -cluster $MAPR_CLUSTER1_NAME -license license3.txt -is_file true
EOF
fi

if [[ "$MAPR_CLUSTER2_COUNT" != "0" ]]; then
   echo 123
fi


################################################################################ 
print_header "Done!"
################################################################################ 