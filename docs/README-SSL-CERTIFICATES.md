## Overview

- The HCP installation script [scripts/bluedata_install.sh](../scripts/bluedata_install.sh) sets up a certificate authority (CA).
- You need to install the certificate authority certificate in your browser (see below)
- You can find the CA certificate in the location: `./generated/ca-cert.pem`.
- The RDP server has the CA certificate automatically installed in the firefox browser.

## HCP Installation Notes

When HCP is installed with SSL, the certificate must be configured in a particular way.  

The installation [docs](http://docs.bluedata.com/50_standard-installation) state the following:

![install docs instructions](./README-SSL-CERTIFICATES/install_docs_ssl_instruction.png)

The **Subject Alternative Name (SAN)** is an extension to X.509 that allows multiple dns names and ip addresses to be added to a SSL certificate. 

The installation scripts in project use [minica](https://github.com/jsha/minica) to simplify creating SSL certificates with the **Subject Alternative Name** correctly populated:

```
   sudo yum -y install git wget
   wget -c --progress=bar -e dotbytes=1M https://dl.google.com/go/go1.13.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz
   if [[ ! -d minica ]];
   then
      git clone https://github.com/jsha/minica.git
      cd minica/
      /usr/local/go/bin/go build
      sudo mv minica /usr/local/bin
   fi
   
   rm -rf /home/centos/${CTRL_PUB_DNS}
   cd /home/centos
   minica -domains "$CTRL_PUB_DNS,$CTRL_PRV_DNS,$GATW_PUB_DNS,$GATW_PRV_DNS,$CTRL_PUB_HOST,$CTRL_PRV_HOST,$GATW_PUB_HOST,$GATW_PRV_HOST,localhost" \
      -ip-addresses "$CTRL_PUB_IP,$CTRL_PRV_IP,$GATW_PUB_IP,$GATW_PRV_IP,127.0.0.1"

   wget -c --progress=bar -e dotbytes=10M -O ${EPIC_INSTALLER_FILENAME} "${EPIC_DL_URL}"
   chmod +x ${EPIC_INSTALLER_FILENAME}
   
   ./${EPIC_INSTALLER_FILENAME} --skipeula --ssl-cert /home/centos/${CTRL_PUB_DNS}/cert.pem --ssl-priv-key /home/centos/${CTRL_PUB_DNS}/key.pem
   ```
   
We can use `openssl x509 -in /home/centos/{minica_output_folder}/cert.pem -text` to view the certificate.  The first **domain** in the `-domains* list is used to create the **minica_output_folder**.  Here is an example extract from the openssl command:

```
            ... 
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:13:D9:0E:3A:86:44:27:8D:9E:C6:04:18:0C:AE:96:48:BF:41:5E:9A

            X509v3 Subject Alternative Name:
                DNS:ec2-54-190-58-4.us-west-2.compute.amazonaws.com, DNS:ip-10-1-0-53.us-west-2.compute.internal, DNS:ec2-52-27-242-248.us-west-2.compute.amazonaws.com, DNS:ip-10-1-0-59.us-west-2.compute.internal, DNS:ec2-54-190-58-4, DNS:ip-10-1-0-53, DNS:ec2-52-27-242-248, DNS:ip-10-1-0-59, DNS:localhost, IP Address:54.190.58.4, IP Address:10.1.0.53, IP Address:52.27.242.248, IP Address:10.1.0.59, IP Address:127.0.0.1
    Signature Algorithm: sha256WithRSAEncryption
         28:0f:a9:49:8f:84:0c:4e:ef:fe:bf:9f:84:fb:b5:07:48:cd:
         3c:07:81:06:3b:ea:96:73:97:f7:d6:3c:d5:b6:76:66:7c:c6:
         75:8f:6a:5e:cb:02:a0:09:d4:07:00:03:ba:e2:06:f6:f7:1e:
         ...
```

In the output you can see that all of the Hostnames and IP addresses for the controllers and gateways have been added to the **X509v3 Subject Alternative Name** field.

### SELINUX

HCP failed to startup in the demo environment when using SSL certificates - the workaround was to disable **SELINUX**.

## CA Certificate browser installation

We need to install the CA certificate in the browser so that the browser can determine if it trusts the connection to to HCP.  The browser will look at the **Subject Alternative Name** declared in the certificate and will verify the **Hostname** in the url and the **IP Address** are found in the SSL **Subject Alternative Name**  field.

The CA cert installation process may be different for each browser and operating system.

- [Chrome](https://www.bonusbits.com/wiki/HowTo:Import_Certificate_Authority_Root_Certificate_in_Google_Chrome)
