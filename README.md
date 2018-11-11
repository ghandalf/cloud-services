## README

The aim of the project is to create a Log Analytic project with ElasticSearch, Kibana, maybe logstach, etc.


#### This repository

 * *cloud-services*: the main container of the project.



#### Set up

We assume that you have already installed docker 18.06.1-ce or over, and docker-compose version 1.23.1 and over.
On Ubuntu machine the update for docker-compose lead you to /usr/local/bin/docker-compose, in fact it as to go under /usr/bin/docker-compose
1. Docker version 18.06.1-ce
2. docker-compose version 1.23.1

Use the script to pull images needed for the project:
1. In a terminal move under cloud-services
2. Make sure that docker.sh is executable: chmod 750 docker.sh | chmod +x docker.sh
3. Execute: ./docker.sh pull

Then you are ready to go. To speed up all call have been done in the docker.sh script, takes time to read it.


#### Contribution guidelines

* Code review
* Other guidelines

#### Technical advice


#### Resources

* Repo owner: Ghandalf
* Community: Slack TBD
