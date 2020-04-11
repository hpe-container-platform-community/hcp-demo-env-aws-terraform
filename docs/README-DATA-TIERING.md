This document is a work-in-progress. Please raise an issue if you encounter an issue or confusion.

----

## Set up data fabric object tiering

### Recommended 

- Read
  - https://mapr.com/docs/61/StorageTiers/Intro.html
  - https://mapr.com/docs/61/AdvancedInstallation/InstallMASTGateway.html
- Watch
  - Manage Data with Volumes and Topology: [link](https://www.youtube.com/watch?v=CwkkojVYruw)
  - MapR Multi-Tier Data Platform - Demo: [link](https://www.youtube.com/watch?v=x0Fpd1jcdsU)

### Install MAST Gateway

SSH into controller, then run:

```
docker exec -it epic-mapr bash
```

Inside the epic-mapr session, run:

```
# TODO: really disable pgpcheck??
yum install -y mapr-mastgateway --nogpgcheck

# This should report the version and the process that MAST Gateway is running as, e.g.
# > 0.20.2 
# > 
# > MASTGATEWAY running as process 339. 
/etc/init.d/mapr-mastgateway status 
```

NOTE: the above settings will be preserved across restarts of the docker container. 