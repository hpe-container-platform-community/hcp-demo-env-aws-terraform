#!/bin/bash

export HIDE_WARNINGS=1

source "./scripts/variables.sh"


./generated/ssh_mapr_cluster_2_host_0.sh sudo -u mapr bash <<EOF
   set -ex

    echo mapr | maprlogin password -user mapr -cluster edge1.enterprise.org
    maprlogin authtest -cluster edge1.enterprise.org

    echo mapr | maprlogin password -user mapr -cluster dc1.enterprise.org
    maprlogin authtest -cluster dc1.enterprise.org

    ######################################################################

    maprcli stream delete \
        -path /mapr/edge1.enterprise.org/apps/pipeline/data/replicatedStream || true

    maprcli stream replica remove \
        -path /mapr/dc1.enterprise.org/apps/pipeline/data/replicatedStream \
        -replica /mapr/edge1.enterprise.org/apps/pipeline/data/replicatedStream || true

    ######################################################################  

    maprcli volume remove \
        -name files-missionX \
        -force true \
        -cluster dc1.enterprise.org || true

    maprcli volume create \
        -name files-missionX \
        -path /apps/pipeline/data/files-missionX \
        -replication 1 \
        -minreplication 1 \
        -cluster dc1.enterprise.org || true

    ######################################################################

    maprcli volume remove \
        -name files-missionX \
        -force true \
        -cluster edge1.enterprise.org || true

    maprcli volume create \
        -name files-missionX \
        -type mirror \
        -source files-missionX@dc1.enterprise.org \
        -mount 1 \
        -path /apps/pipeline/data/files-missionX \
        -topology /data \
        -auditenabled true \
        -cluster edge1.enterprise.org || true

EOF

    
./bin/mapr_edge_demo_poststartup_edge_replica.sh
./bin/mapr_edge_demo_poststartup_mirror.sh
./bin/mapr_edge_demo_poststartup_auditing.sh