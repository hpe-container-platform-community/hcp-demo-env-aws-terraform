#sudo mv /usr/lib/firefox/libnssckbi.so /usr/lib/firefox/libnssckbi.so.bak
#sudo ln -s /usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so /usr/lib/firefox/libnssckbi.so


openssl x509 -outform der -in /home/ubuntu/hcp-ca-cert.pem -out /home/ubuntu/hcp-ca-cert.crt
sudo cp /home/ubuntu/hcp-ca-cert.crt /usr/share/ca-certificates/
sudo bash -c 'echo hcp-ca-cert.crt >> /etc/ca-certificates.conf'
sudo update-ca-certificates

sudo apt install libnss3-tools

rm -rf /home/${USER}/.mozilla/

installId="4F96D1932A9F858E" # hash of firefox install location
defaultProfileId=$(openssl rand -hex 4)
releaseProfileId=$(openssl rand -hex 4)

certificateFile="/home/${USER}/hcp-ca-cert.pem"
certificateName="HCP CA Cert"

#########

certDir="/home/${USER}/.mozilla/firefox/${defaultProfileId}.default"
mkdir -p $certDir
certutil -A -n "${certificateName}" -t "TCu,Cu,Tu" -i "${certificateFile}" -d "sql:/${certDir}"

certDir="/home/${USER}/.mozilla/firefox/${releaseProfileId}.default-release"
mkdir -p $certDir
certutil -A -n "${certificateName}" -t "TCu,Cu,Tu" -i "${certificateFile}" -d "sql:${certDir}"

#########

cat << EOF >> /home/${USER}/.mozilla/firefox/profiles.ini
[Install${installId}]
Default=${defaultProfileId}.default
Locked=1

[Profile1]
Name=default
IsRelative=1
Path=${defaultProfileId}.default
Default=1

[Profile0]
Name=default-release
IsRelative=1
Path=${releaseProfileId}.default

[General]
StartWithLastProfile=1
Version=2
EOF

#########

cat << EOF >> /home/${USER}/.mozilla/firefox/installs.ini
[${installId}]
Default=${releaseProfileId}.default
Locked=1
EOF

#########

echo ${installId}
echo ${defaultProfileId}
echo ${releaseProfileId}


