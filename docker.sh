#!/bin/bash

###
## Use to stars current docker configs
##
##
## Author: Ghandalf
###

application=$0
command=$1
args=$2

###
# Pull the images with the define version in docker.properties files
#
##
function pull() {
    for i in "${images[@]}"; do
        docker pull $i;
    done
}

function loadResources() {
	echo -e "\n\t\t $0 load resources...";
	if [ -f ./config/docker.properties ]; then
		source ./config/docker.properties;
	else
		echo -e "\n\t\t${BRed}You need to provide the file docker.properties under config directory...${Color_Off}\n";
	fi
	if [ -f ./env/colors.properties ]; then
		source ./env/colors.properties;
	else
		echo -e "\n\t\t${BRed}You need to provide colors.properties file under env directory...${Color_Off}\n";
	fi
}

###
# Create or remove analytic network
##
function network() {
    local result=`docker network ls | grep ${analytic_network} | awk {'printf "%s\n", $2'}`;
	local exist_message="\n\t\tThe docker network [${analytic_network}] already exists.";
    case $1 in
		create)
    		#echo -e "RESULT: $result";
    		if [ $result ]; then
        		echo -e $exist_message;
    		else 
        		echo -e "\n\t\tCreating docker network [${analytic_network}]";
        		docker network create ${analytic_network} --driver=bridge;
    		fi
			;;
		remove)
			if [ $result ]; then
				echo -e "\n\t\tRemoving docker network [${analytic_network}]";
				docker network rm ${analytic_network};
			else
				echo -e "\n\t\tDocker network [${analytic_network}] doesn't exist.";
			fi
			;;
		*)
			echo -e "\n\t\t${BRed}Please you need to provide a sub command <create|remove>.${Color_Off}";
			;;
	esac
	docker network ls;
}

###
# Start the analytice containers link together thru a bridge network
##
function startAnalytic() {

    network create;
    
    for i in "${images[@]}"; do
        local containerName=`echo $i | awk -F'/' {'printf $3'} | awk -F':' {'printf $1'}`
        local result=`docker container ls -q -f name=$containerName`
        
        if [ $result ]; then 
            echo -e "\n\tContainer $containerName is running will be stopped, removed and restarted.";
            docker stop $containerName;
            docker rm $containerName;
        fi
        case $containerName in
            elasticsearch)
                # see: httpans://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html
                docker run --name $containerName -p 9200:9200 -p 9300:9300 -d --network ${analytic_network} $i
                ;;
            kibana)
                docker run --name $containerName -p 5601:5601 -d --network ${analytic_network} $i;
                ;;
        esac
    done
	docker ps -a;
}

function stopAnalytic() {
  
    for i in "${images[@]}"; do
        local containerName=`echo $i | awk -F'/' {'printf $3'} | awk -F':' {'printf $1'}`;
		# echo -e "ContainerName: $containerName";
        
        echo -e "\n\tContainer $containerName is running will be stopped and removed.";
        docker stop $containerName;
        docker rm $containerName;
    done

    network remove;
	docker ps -a;
}

###
# This function will start the container by using command line for analytic, and 
# docker-compose.yml file for the swarm.
# Best practice is to use the swarm configuration.
##
function start() {
	case $1 in
		analytic)
			stopAnalytic;
			startAnalytic;	
			;;
		swarm)
			# compose needs to shutdown all background processing before starting them.
			docker-compose -f $compose_file down;
			docker-compose -f $compose_file up;
			;;
		*)
			echo -e "\n\t\t${BRed}Please you need to provide a sub command <analytic|swarm>.${Color_Off}";
			;;
	esac
}

function stopSwarm() {
	docker-compose -f $compose_file down;
	docker swarm leave --force;
}

function stop() {
	case $1 in
		analytic)
			stopAnalytic;
			;;
		swarm)
			stopSwarm;
			;;
		*)
			echo -e "\n\t\tPlease you need to provide a sub command <analytic|swarm>";
			;;
	esac
}

###
# Remove all containers, networks and force leaving the swarm due to manager container.
#
##
function clean() {
    echo -e "\n\t\tRemove background running containers\n";
	for i in "${images[@]}"; do
		local containerName=`echo $i | awk -F'/' {'printf $3'} | awk -F':' {'printf $1'}`;
    	docker stop $containerName;
    	docker rm $containerName;
	done

	local result=`docker network ls --filter 'name=$analytic_network' | grep $analytic_network | awk {'printf $2'}`;
	if [ $result ]; then
		docker network rm ${analytic_network};
	fi

	docker swarm leave --force;
    echo -e "\n";
}

function info() {
	docker-compose -f $compose_file config;
	# docker-compose -f $compose_prod_file config;
	docker images;
	echo -e "\n";
	docker ps;
	echo -e "\n";
	docker network ls;
	#docker service ls;
	echo -e "\n";
}

function status() {
	echo -e "\n\t\tKibana status...";
	curl -s localhost:5601/api/status;

	echo -e "\n\n\t\tElastich search status...";
	curl -s -f -u elastic:changeme http://localhost:9200/_cat/health;
	echo -e "\n\n\t\tElastich search info...";
	curl -s localhost:9200/;
}

###
# Contain configuration needed for ElasticSearch and Kibana
##
function configuration() {
	echo -e "\n\t\t${BRed}Not emplemented yet...${Color_Off}";
}

function validate() {
	case $1 in
		local)
			docker-compose -f $compose_file config;
			;;
		prod)
			docker-compose -f $compose_prod_file config;
			;;
		*)
			echo -e "\n\t\t${BRed}Please you need to provide argument <local|prod>.${Color_Off}";
		;;
	esac
}

function usage() {
    echo -e "\n\tUsage:";
    echo -e "\t\t$0 <pull|clean|start|stop|clean|info|status|validate>";
	echo -e "\n";
}

function finish() {
	echo -e "\n\t\t${Cyan}Not implemented yet. Will be a graceful shutdown process...${Color_Off}\n";
}
trap finish EXIT;

loadResources;

case ${command} in
	pull)
		pull;
		;;
	network)
		network $args;
		;;
	start)
		start $args;
		;;
	stop)
		stop $args;
		;;
	clean)
		clean;
		;;
	info)
		info;
		;;
	status)
		status;
		;;
	validate)
		validate $args;
		;;
    *) 
		usage;
		;;
esac
