#!/bin/bash

###
## Use to configure postgres, oracle, redis databases, users, tables, etc.
##
##
## Author: Ghandalf

function start() {
    echo -e "\n\tStarting containers...";

	for i in "${images[@]}"; do
	    case $i in 
	        dockerhelp/docker-oracle-ee-18c)    
	            docker run --name docker-oracle18c -d -p 8090:8090 -p 1523:1523 -v ${oracle18_data}:/opt/app/oracle18 $i
    	        echo -e "\n\t Oracle 18c started with data: ${oracle18_data}\n";
            	;;
        	sath89/oracle-12c)    
            	# docker run -d -p 8080:8080 -p 1521:1521 --name docker-oracle -v /data/app/db/OracleDataDocker/oracle:/u01/app/oracle sath89/oracle-12c
            	docker --name docker-oracle12c run -d -p 8080:8080 -p 1521:1521 -v ${oracle12_data}:/opt/app/oracle $i
            	echo -e "\n\t Oracle 12c started with data: ${oracle12_data}\n";
            	;;
        	postgres)
            	#docker run -d -p 5432:5432 --name docker-postgres -v ${postgres_data} -e POSTGRES_PASSWORD=postgres postgres
            	#docker run -d -p 5432:5432 --name docker-postgres -v postgresql-data:/data/app/db/PostgreSQLDataDocker/postgresql -e POSTGRES_DB=UrbanMobility -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres postgres
            	docker run --name docker-postgres -d -p 5432:5432 -v ${postgres_data}:/opt/app/postgres -e POSTGRES_DB=UrbanMobility -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres $i
            	#docker start 0a3e218c1b36
            	echo -e "\n\t PostgreSQL started with data:${postgres_data}\n";
            	;;
        	redis)
            	docker run --name docker-redis -d -p 6379:6379 -v ${redis_data}:/opt/app/redis $i
            	echo -e "\n\t Redis started\n";
            	;;
	    esac  
    done
}

function stop() {
    echo -e "\n\tStopping all containers\n";
    docker container stop $(docker ps -aq)
    echo -e "\n\tAll containers stopped\n";   
}

function clean() {

    echo -e "\n\t Remove background running containers\n"
    docker stop $(docker ps -aq)
    docker rm $(docker ps -aq)
	
    echo -e "\n\t Containers removed \n"
    docker ps -aq
    
    echo -e "\n";
}

function createUser() {
	psql -h localhost -p 5432 -d UrbanMobility -f ./scripts/postgresql/CreateDB.sql -U postgres
	psql -h localhost -p 5432 -d UrbanMobility -f ./scripts/postgresql/CreateUser.sql -U postgres 
}

function dropTables() { 
	psql -h localhost -p 5432 -d UrbanMobility -f ./scripts/postgresql/DropTables.sql -U postgres
}

function createTables() { 
	psql -h localhost -p 5432 -d UrbanMobility -f ./scripts/postgresql/CreateTables.sql -U postgres
}

function insertData() { 
	psql -h localhost -p 5432 -d UrbanMobility -f ./scripts/postgresql/InsertData.sql -U postgres
}

function loadResources() {
	echo -e "\n\t\t $0 load resources...";
	if [ -f ./container/db.properties ]; then
		source ./container/db.properties;
	else
		echo -e "\n\t\tYou need to provide the file db.properties under container directory...";
		echo -e "\n";
	fi
}

function pull() {
    for i in "${images[@]}"; do
        docker pull $i;
    done
}

function show() {
    echo -e "\n\tDocker container installed";
    docker images
    echo -e "\n\tDocker running";
    docker ps 
    echo -e "\n\tDocker network";
    docker network ls
    echo -e "\n";
}

function finish() { 
	echo -e "\n\t\tUse to clean resources before we live\n";
}
trap finish EXIT;

# password: postgres
loadResources;

case $1 in 
    start)
        start $2;
        ;;
	stop)
		stop;
		;;
	clean)
		clean;
		;;
	create)
		createTables;
		;;
	insert)
		insertData;
		;;
	drop)    
		dropTables;
		;;
	pull)
		pull;
		;;
    show)
        show;
        ;;
	user)
		createUser;
		;;
	*)
       echo -e "\n\t Please provide a command: <start|stop|clean|create|insert|drop|pull|user> \n";
        ;;
esac

# docker run --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword -d postgres
# docker run --name dock-postgres -e POSTGRES_PASSWORD=apirest -d postgres

#program_dir=/data/app/programs/tor/tor-browser_en-US/
#program=start-tor-browser.desktop

#cd $program_dir
#./$program 
#cd $current_dir