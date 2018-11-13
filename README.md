## README
The aim of the project is to create a Log Analytic project with ElasticSearch, Kibana, maybe logstach, etc.

#### This repository
 * *cloud-services*: the main container of the project.

#### Set up
We assume that you have already installed on your local machine docker, docker-compose, docker-machine.
If not follow this [link](https://docs.docker.com/install/).

You need to clone the project from the repository. 
- git clone <url>

On Ubuntu machine the update for docker-compose lead you to /usr/local/bin/docker-compose, in fact it as to go under /usr/bin/docker-compose
1. Docker version 18.06.1-ce
2. docker-compose version 1.23.1
3. docker-machine version v0.16.0

I have created a script to avoid hand writing, some command are long and error prone.
Use the script to pull images needed for the project. 
1. In a terminal move under cloud-services
2. Make sure that service.sh is executable: 
   - chmod 750 service.sh | chmod +x docker.sh
3. Execute: 
   - ./service.sh pull
    - It will pull all containers for the project.

Then you are ready to go.
Some commands you can use with the script
1. ./service.sh start swarm   ## Will start all containers 
2. Open an other terminal, move under the project, execute
   - ./service.sh info
   - ./service.sh status

#### Contribution guidelines
* Code review
* Other guidelines

#### Technical advice


#### Resources
* Repo owner: Ghandalf
* Community: Slack TBD
