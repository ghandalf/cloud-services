!#/bin/sh

###
## I need to create an other file with module info how to
## see: https://www.oracle.com/corporate/features/understanding-java-9-modules.html
##
##
###


###
## Simple script to install databases docker
##
## Note: Take a look to this page help to clean our docker installations
##      https://www.projectatomic.io/blog/2015/07/what-are-docker-none-none-images/
##      The main point is to clean up our dockers references by executing
##      docker rmi $(docker images -f dangling=true -q)
## 
##
## author: Ghandalf
###

###
# Some docker commands without the bla bla that you can find at
# https://docs.docker.com/engine/reference/
##
# docker ps // show all running images or containers - They need to clarify their focking terms
# docker run // Complex one
# docker run -d -p 8080:8080 -p 1521:1521 sath89/oracle-12c


# Pull postgresql database

# see: https://hub.docker.com/r/library/postgres/
# Retrieve the latest postgresql database
docker pull postgres
docker run -it --rm --link dock-postgres:postgres postgres psql -h postgres -U postgres

docker run --name some-postgres -e POSTGRES_PASSWORD=restapi -d postgres


###### Oracle #######

### Official ###
# see: http://oracle-help.com/articles/prebuilt-oracle-database-18c-with-docker/
# docker pull dockerhelp/docker-oracle-ee-18c

# docker images | tail -2
docker images | grep oracle-ee-18c | awk '{print $1}'


### Sath89 ###
# see: https://hub.docker.com/r/sath89/oracle-12c/
docker pull sath89/oracle-12c # will pull or update the image/container

## Will start the container with the database data
docker run --debug -p 8080:8080 -p 1521:1521 -v /data/app/db/OracleDataDocker/oracle:/u01/app/oracle sath89/oracle-12c

## Connection 
# use Oracle Thin(Service ID (SID) with one of those drivers
# 
