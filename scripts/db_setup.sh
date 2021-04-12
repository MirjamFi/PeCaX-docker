#!/bin/sh

# 1. create the /vol dir
mkdir -p /vol

# 2a. create /vol/plugins folder
mkdir -p /vol/plugins
# 2b. Download Apoc

[ ! -e /vol/plugins/apoc-4.1.0.2-all.jar ] && wget -P /vol/plugins https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/4.1.0.2/apoc-4.1.0.2-all.jar

# 3. create /vol/logs
mkdir -p /vol/logs

# 4. create /vol/conf
mkdir -p /vol/conf
touch /vol/conf/neo4j.conf

# 5. check if data is there and copy it
cd /
mkdir -p /vol/data
[ -e /data/pecax.tar.gz ] && tar x -C /vol/data -z -f /data/pecax.tar.gz --strip 1  

# 6. Fix permission settings
chown -R 7474:7474 vol
chmod 600 /vol/conf/neo4j.conf


