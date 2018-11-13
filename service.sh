#!/bin/bash

###
## Use to stars current docker configs
##
## Author: fouellet@dminc.com
###

application=$0
command=$1
args=$2
double_tab="\t\t"

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
	echo -e "\n${double_tab}$0 load resources...";
	if [ -f ./config/docker.properties ]; then
		source ./config/docker.properties;
	else
		echo -e "\n${double_tab}${BRed}You need to provide the file docker.properties under config directory...${Color_Off}\n";
	fi
	if [ -f ./env/colors.properties ]; then
		source ./env/colors.properties;
	else
		echo -e "\n${double_tab}${BRed}You need to provide colors.properties file under env directory...${Color_Off}\n";
	fi
}

###
# Create or remove analytic network
##
function network() {
    local result=`docker network ls | grep ${analytic_network} | awk {'printf "%s\n", $2'}`;
	local exist_message="\n${double_tab}The docker network [${analytic_network}] already exists.";
    case $1 in
		create)
    		#echo -e "RESULT: $result";
    		if [ $result ]; then
        		echo -e $exist_message;
    		else 
        		echo -e "\n${double_tab}Creating docker network [${analytic_network}]";
        		docker network create ${analytic_network} --driver=bridge;
    		fi
			;;
		remove)
			if [ $result ]; then
				echo -e "\n${double_tab}Removing docker network [${analytic_network}]";
				docker network rm ${analytic_network};
			else
				echo -e "\n${double_tab}Docker network [${analytic_network}] doesn't exist.";
			fi
			;;
		*)
			echo -e "\n${double_tab}${BRed}Please you need to provide a sub command <create|remove>.${Color_Off}";
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
			stopAnalytic && startAnalytic;	
			;;
		swarm)
			# compose needs to shutdown all background processing before starting them.
			docker-compose -f $compose_file down && docker-compose -f $compose_file up;
			;;
		*)
			echo -e "\n${double_tab}${BRed}Please you need to provide a sub command <analytic|swarm>.${Color_Off}";
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
			echo -e "\n${double_tab}Please you need to provide a sub command <analytic|swarm>";
			;;
	esac
}

###
# Remove all containers, networks and force leaving the swarm due to manager container.
#
##
function clean() {
    echo -e "\n${double_tab}Remove background running containers\n";
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
	echo -e "\n${double_tab}${Yellow}Kibana${Color_Off} status: \n${Green}`curl -s -f localhost:5601/api/status`${Color_Off}";

	echo -e "\n\n${double_tab}${Yellow}ElasticSearch${Color_Off} status: ${Green}`curl -s -f -u elastic:changeme http://localhost:9200/_cat/health`${Color_Off}";
	
	echo -e "\n\n${double_tab}${Yellow}ElasticSearch${Color_Off} info: \n${Green}`curl -s localhost:9200/`${Color_Off}";
}

###
# Create keystore and certificate
# We will need to use the customer certificate.
##
function setUpSecurity() {
	local ELASTIC_PASSWORD="changeme";
	local certificate="$ELASTIC_PASSWORD:-`openssl rand -base64 64`";
	echo -e "Certificate: $certificate";

	# passphrase used: dmiforcfna
	# Generate private key
	openssl genrsa -des3 -out config/ssl/ca/dmiCA.key 4096
	# Generate root certificate for 5 years
	openssl req -x509 -new -nodes -key config/ssl/ca/dmiCA.key -sha256 -days 1825 -out config/ssl/ca/dmiCA.pem
}

###
# Contain configuration needed for ElasticSearch and Kibana
##
function configuration() {
	echo -e "\n${double_tab}${BRed}Not emplemented yet...${Color_Off}";
}

function validate() {
	case $1 in
		local)
			docker-compose -f ${compose_file} config;
			;;
		prod)
			docker-compose -f ${compose_prod_file} config;
			;;
		*)
			echo -e "\n${double_tab}${BRed}Please you need to provide argument <local|prod>.${Color_Off}";
		;;
	esac
}

###
# Update docker, docker-machine and docker-compose on any container manager.
# This function must be used for a docker manager only.
# FIXME: activate this function when all containers are ready for deployment.
##
function update() {
	case $args in
		docker)
			echo -e "\n${double_tab}${Green}docker version [${Red}`docker --version`${Green}] \n" \
				"${double_tab}docker-compose [${Red}`docker-compose --version`${Green}] \n" \
				"${double_tab}docker-machine [${Red}`docker-machine --version`${Green}] \n" \
				"${double_tab}will be updated with the latest release. \n" \
				"${double_tab}Important note we are running in experimental mode: [${Red}'`docker version -f {{.Server.Experimental}}`'${Green}] \n" \
				"${double_tab}If true, ${Yellow}you will have to change the value when you go in production.${Color_Off}";

			local OS=`uname -s`;
			case $OS in 
				Darwin)
					curl -L ${docker_compose_url}/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` > ${docker_mac_path}/docker-compose && 
							chmod +x ${docker_mac_path}/docker-compose
					
					curl -L ${docker_machine_url}/${docker_machine_version}/docker-machine-`uname -s`-`uname -m` > ${docker_mac_path}/docker-machine && 
							chmod +x ${docker_mac_path}/docker-machine
					;;
				linux)
					echo -e "\nLINUX: curl -L ${docker_compose_url}/${docker_compose_version}/docker-compose-`uname -s`-`uname -m` > /tmp/docker-compose && 
						chmod +x /tmp/docker-compose &&
						sudo cp /tmp/docker-compose ${docker_linux_path}/docker-compose"

					echo -e "\nLINUX: curl -L ${docker_machine_url}/${docker_machine_version}/docker-machine-`uname -s`-`uname -m` > /tmp/docker-machine && 
						chmod +x /tmp/docker-machine &&
						sudo cp /tmp/docker-machine ${docker_linux_path}/docker-machine"
					;;
				windows)
					echo -e "\nWINDOWS: if [[ ! -d '${docker_windows_path}' ]]; then mkdir -p '${docker_windows_path}'; fi && 
						curl -L ${docker_compose_url}/${docker_compose_version}/docker-compose-Windows-x86_64.exe > '${docker_windows_path}/docker-compose.exe' && 
						chmod +x '${docker_windows_path}/docker-compose.exe'"
					
					echo -e "\nWINDOWS: if [[ ! -d '${docker_windows_path}' ]]; then mkdir -p '${docker_windows_path}'; fi && 
						curl -L ${docker_machine_url}/${docker_machine_version}/docker-machine-Windows-x86_64.exe > '${docker_windows_path}/docker-machine.exe' && 
						chmod +x '${docker_windows_path}/docker-machine.exe'"
					;;
			esac
			;;
		*)
			echo -e "\n${double_tab}${BRed}Please you need to provide argument <docker>.${Color_Off}";
			;;
	esac
}

function diagnose() {
	${docker_diagnose} gather
}

function usage() {
    echo -e "\n\tUsage:";
    echo -e "${double_tab}$0 <pull|clean|start|stop|clean|info|status|validate|security>";
	echo -e "\n";
}

function finish() {
	echo -e "\n${double_tab}${Cyan}Function finish() is not implemented yet. Will be a graceful shutdown process...${Color_Off}\n";
}
trap finish EXIT;

loadResources;

case ${command} in
	clean)
		clean;
		;;
	diagnose)
		diagnose;
		;;
	info)
		info;
		;;
	network)
		network $args;
		;;
	pull)
		pull;
		;;
	security)
		setUpSecurity;
		;;
	start)
		start $args;
		;;
	stop)
		stop $args;
		;;
	status)
		status;
		;;
	update)
		update $args;
		;;
	validate)
		validate $args;
		;;
    *) 
		usage;
		;;
esac
