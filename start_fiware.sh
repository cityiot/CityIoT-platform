#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# This script setups the CityIoT FIWARE platform and all the services.

# load enviroment variables
source main_settings.env
source extra_settings.env

##############################################################################
# initialize the swarm
##############################################################################

swarm_state=$(docker info --format '{{.Swarm.LocalNodeState}}')
if [ "$swarm_state" != "active" ]
then
    echo "Initializing Docker swarm mode."
    docker swarm init --advertise-addr 192.168.99.1
fi

##############################################################################
# increase the vm.max_map_count (only needs to be done once)
##############################################################################

vm_max_map_count=$(sysctl vm.max_map_count | awk '{print $NF}')
if [[ $vm_max_map_count != 262144 ]]
then
    echo "Changing vm.max_map_count to 262144."
    sudo sysctl -w vm.max_map_count=262144
fi

##############################################################################
# create the network for the services
##############################################################################

cityiot_network=$(docker network ls | grep cityiot)
if [ "$cityiot_network" == "" ]
then
    echo "Creating $CITYIOT_NETWORK_NAME Docker network."
    docker network create --driver overlay --scope swarm ${CITYIOT_NETWORK_NAME:-cityiot}
else
    cityiot_network_driver=$(echo "$cityiot_network" | awk '{print $3}')
    if [ "$cityiot_network_driver" != "overlay" ]
    then
        echo "The Docker network $cityiot_network_driver already exists but its driver is not overlay."
        echo "Remove the network and try again:\n  docker network rm $cityiot_network_driver"
        exit 1
    fi

    cityiot_network_scope=$(echo "$cityiot_network" | awk '{print $4}')
    if [ "$cityiot_network_scope" != "swarm" ]
    then
        echo "The Docker network $cityiot_network_driver already exists but its scope is not swarm."
        echo "Remove the network and try again:\n  docker network rm $cityiot_network_driver"
        exit 1
    fi
fi

##############################################################################
# Adjust the configuration files according to the settings given in main_settings.env.
##############################################################################

source update_configurations.sh

##############################################################################
# Deploy the Docker stacks.
# NOTE: there should be some delay between these so that the previous stack is full deployed before the next stack
##############################################################################

echo "Deploying Mongo database."
docker stack deploy -c docker-compose-mongo.yml ${MONGO_STACK_NAME:-mongo-rs}
sleep 30

echo "Deploying Orion Context Broker."
docker stack deploy -c docker-compose-orion.yml ${ORION_STACK_NAME:-orion}
sleep 30

if [ "$FIWARE_INCLUDE_QUANTUMLEAP" == "true" ]
then
    echo "Deploying QuantumLeap."
    docker stack deploy -c docker-compose-quantumleap.yml ${QL_STACK_NAME:-ql}
    sleep 30
fi

if [ "$FIWARE_INCLUDE_IOTAGENT_UL" == "true" ]
then
    echo "Deploying IoT Agent for the Ultralight 2.0 protocol."
    docker stack deploy -c docker-compose-iotagent.yml ${IOTAGENT_UL_STACK_NAME:-iotagent}
    sleep 30
fi

# deploy the utility stacks (Grafana, Wirecloud, CKAN, PostgreSQL, etc.)
if [ "$FIWARE_INCLUDE_GRAFANA" == "true" ] ||
   [ "$FIWARE_INCLUDE_WIRECLOUD" == "true" ] ||
   [ "$FIWARE_INCLUDE_CKAN" == "true" ]
then
    echo "Deploying the utilities stack."
    docker stack deploy -c docker-compose-util.yml ${UTIL_STACK_NAME:-util}
    sleep 30
else
    # also deploy the utilities stack if QuantumLeap needs Redis.
    if [ "$FIWARE_INCLUDE_QUANTUMLEAP" == "true" ] && [ "$QL_USE_GEOCODING" == "true" ]
    then
        echo "Deploying the utilities stack2."
        docker stack deploy -c docker-compose-util.yml ${UTIL_STACK_NAME:-util}
        sleep 30

        # Since the initializing scripts for postgres container are run only for a new Docker volume,
        # run the database and user creating script separately after the container has started
        docker exec -it $(docker ps | grep ${UTIL_STACK_NAME:-util}_${POSTGRES_SERVICE_URI:-postgresdb} | awk '{print $1}') /docker-entrypoint-initdb.d/create-multiple-postgresql-databases.sh
        sleep 30
    fi
fi

if [ "$FIWARE_INCLUDE_GRAFANA" == "true" ]
then
    echo "Deploying Grafana."
    docker stack deploy -c docker-compose-grafana.yml ${GRAFANA_STACK_NAME:-grafana}
    sleep 30
fi

if [ "$FIWARE_INCLUDE_WIRECLOUD" == "true" ]
then
    echo "Deploying Wirecloud."
    docker stack deploy -c docker-compose-wirecloud.yml ${WIRECLOUD_STACK_NAME:-wirecloud}
    sleep 30
fi

if [ "$FIWARE_INCLUDE_CKAN" == "true" ]
then
    echo "Deploying CKAN."
    docker stack deploy -c docker-compose-ckan.yml ${CKAN_STACK_NAME:-ckan}
    sleep 30
fi

##############################################################################
# Deploy the Nginx service using its own script.
##############################################################################

echo "Deploying Nginx proxy server."
source update_nginx.sh
