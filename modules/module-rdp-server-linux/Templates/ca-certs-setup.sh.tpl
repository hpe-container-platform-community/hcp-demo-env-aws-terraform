#!/bin/bash

#sudo mv /usr/lib/firefox/libnssckbi.so /usr/lib/firefox/libnssckbi.so.bak
#sudo ln -s /usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so /usr/lib/firefox/libnssckbi.so

CONTROLLER_PRIVATE_IP=${controller_private_ip}

# add HCP CA cert to Ubuntu system certificates

if [[ ! -f /usr/share/ca-certificates/hcp-ca-cert.crt ]];
then
    openssl x509 -outform der -in /etc/skel/hcp-ca-cert.pem -out /tmp/hcp-ca-cert.crt
    sudo cp /tmp/hcp-ca-cert.crt /usr/share/ca-certificates/
    sudo bash -c 'echo hcp-ca-cert.crt >> /etc/ca-certificates.conf'
    sudo update-ca-certificates
    
    sudo apt -qq install libnss3-tools
fi

# the rest of this script adds the HCP CA cert to the mozilla user profiles
# and also setups the homepage to the controller

rm -rf /home/$${USER}/.mozilla/

installId="4F96D1932A9F858E" # hash of firefox install location
defaultProfileId=$(openssl rand -hex 4)
releaseProfileId=$(openssl rand -hex 4)

certificateFile="/etc/skel/hcp-ca-cert.pem"
certificateName="HCP CA Cert"

#########

certDir="/home/$${USER}/.mozilla/firefox/$${defaultProfileId}.default"
mkdir -p $${certDir}
certutil -A -n "$${certificateName}" -t "TCu,Cu,Tu" -i "$${certificateFile}" -d "sql:/$${certDir}"
echo "pref(\"browser.startup.homepage\", \"https://$${CONTROLLER_PRIVATE_IP}|https://$${CONTROLLER_PRIVATE_IP}:8443\");" >> $${certDir}/user.js

certDir="/home/$${USER}/.mozilla/firefox/$${releaseProfileId}.default-release"
mkdir -p $${certDir}
certutil -A -n "$${certificateName}" -t "TCu,Cu,Tu" -i "$${certificateFile}" -d "sql:$${certDir}"
echo "pref(\"browser.startup.homepage\", \"https://$${CONTROLLER_PRIVATE_IP}|https://$${CONTROLLER_PRIVATE_IP}:8443\");" >> $${certDir}/user.js

#########

cat << EOF >> /home/$${USER}/.mozilla/firefox/profiles.ini
[Install$${installId}]
Default=$${defaultProfileId}.default
Locked=1

[Profile1]
Name=default
IsRelative=1
Path=$${defaultProfileId}.default
Default=1

[Profile0]
Name=default-release
IsRelative=1
Path=$${releaseProfileId}.default

[General]
StartWithLastProfile=1
Version=2
EOF

#########

cat << EOF >> /home/$${USER}/.mozilla/firefox/installs.ini
[$${installId}]
Default=$${releaseProfileId}.default
Locked=1
EOF

#########

echo $${installId}
echo $${defaultProfileId}
echo $${releaseProfileId}


