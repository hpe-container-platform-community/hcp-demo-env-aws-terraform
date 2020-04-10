### K8S Application Catalog empty after restarting instances

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

### Running Kube Director Applications not showing after restarting instances

See 'K8S Application Catalog empty after restarting instances'

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
