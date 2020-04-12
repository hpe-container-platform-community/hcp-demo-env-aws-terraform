### K8S Application Catalog is empty

SSH into the controller and restart the container `epic/authproxy:1.6`.  E.g.

```
[centos@ip-10-1-0-152 ~]$ docker ps
CONTAINER ID        IMAGE                               COMMAND                  CREATED             STATUS              PORTS               NAMES
b1023f0753eb        epic/authproxy:1.6                  "nginx -p /home/op..."   22 hours ago        Up About a minute                       epic-auth-proxy-k8s-id-1
2a81d3ec1c7b        epic/webhdfs:1.2                    "httpfs.sh run"          22 hours ago        Up About a minute                       epic-webhdfs-10.1.0.152
cac8a9c4b708        epic/monitoring:1.17                "/etc/start-all.sh..."   22 hours ago        Up 21 seconds                           epic-monitoring-10.1.0.152
dc4cc055ff3e        epic/nagios:2.4                     "/bin/sh -c '/usr/..."   22 hours ago        Up About a minute                       epic-nagios-10.1.0.152
7537305039b5        epic/mapr:6.1.0-GA-20200210022930   "/sbin/init"             22 hours ago        Up About a minute                       epic-mapr
[centos@ip-10-1-0-152 ~]$ docker restart b1023f0753eb
```

### Running Kube Director Applications are not displayed

See [above](#k8s-application-catalog-is-empty)

### Can't login to MCS - Login Denied

1. If you have just started your EC2 instances, allow a few minutes for MAPR docker container to fully start
2. If step 1 fails, ssh into the controller and restart the epic-mapr docker container (docker restart <<epic-mapr container id>>
3. If step 2 fails, restart the controller EC2 instance

### Can't connect to AD/LDAP Server

The password has likely expired.  Log into the host where the AD/LDAP is running.

```
docker ps -a
```
to get docker container ID

```
docker exec -it <container ID> /bin/bash
```

run the following command
```
samba-tool domain passwordsettings set --max-pwd-age=999
```
