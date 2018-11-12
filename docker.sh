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
		echo -e "\n\t\tYou need to provide the file docker.properties under container directory...";
		echo -e "\n";
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
			echo -e "\n\t\tPlease you need to provide a sub command <create|remove>";
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

function start() {
	case $1 in
		analytic)
			stopAnalytic;
			startAnalytic;	
			;;
		swarm)
			docker-compose -f $compose_file down;
			docker-compose -f $compose_file up;
			;;
		*)
			echo -e "\n\t\tPlease you need to provide a sub command <analytic|swarm>";
			;;
	esac
}

function stop() {
	case $1 in
		analytic)
			stopAnalytic;
			;;
		swarm)
			docker-compose -f $compose_file down;
			docker swarm leave --force;
			;;
		*)
			echo -e "\n\t\tPlease you need to provide a sub command <analytic|swarm>";
			;;
	esac
}

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

function validate() {
	case $1 in
		local)
			docker-compose -f $compose_file config;
			;;
		prod)
			docker-compose -f $compose_prod_file config;
			;;
		*)
			echo -e "\n\t\tPlease you need to provide argument <local|prod>";
		;;
	esac
}

function usage() {
    echo -e "\n\tUsage:";
    echo -e "\t\t$0 <pull|clean|db|start|startAnalytic|show|stop>";
	echo -e "\t\t\tstartAnalytic: will start the containers wihtout docker.compose.yml"
    echo -e "\n";
}

function finish() {
	echo -e "\n\t\tUse to clean resources before we live\n";
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
	validate)
		validate $args;
		;;
    *) 
		usage;
		;;
esac
