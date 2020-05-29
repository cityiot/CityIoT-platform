#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# This starts all the services for the CityIoT FIWARE platform.
# It assumes that all configuration files are up to date and other initializations
# like setting up the Docker network is done.
# This script is meant to be used in the case where a new component is added to a running platform
# or as an easy way to restart a component in the platform that was manually removed.

# load enviroment variables
source main_settings.env
source extra_settings.env

##############################################################################
# Deploy the Docker stacks.
# NOTE: No delays between the deploy stack commands are used in this script.
##############################################################################

echo "Deploying Mongo database."
docker stack deploy -c docker-compose-mongo.yml ${MONGO_STACK_NAME:-mongo-rs}

echo "Deploying Orion Context Broker."
docker stack deploy -c docker-compose-orion.yml ${ORION_STACK_NAME:-orion}

if [ "$FIWARE_INCLUDE_QUANTUMLEAP" == "true" ]
then
    echo "Deploying QuantumLeap."
    docker stack deploy -c docker-compose-quantumleap.yml ${QL_STACK_NAME:-ql}
fi

if [ "$FIWARE_INCLUDE_IOTAGENT_UL" == "true" ]
then
    echo "Deploying IoT Agent for the Ultralight 2.0 protocol."
    docker stack deploy -c docker-compose-iotagent.yml ${IOTAGENT_UL_STACK_NAME:-iotagent}
fi

# deploy the utility stacks (Grafana, Wirecloud, CKAN, PostgreSQL, etc.)
if [ "$FIWARE_INCLUDE_GRAFANA" == "true" ] ||
   [ "$FIWARE_INCLUDE_WIRECLOUD" == "true" ] ||
   [ "$FIWARE_INCLUDE_CKAN" == "true" ]
then
    echo "Deploying the utilities stack."
    docker stack deploy -c docker-compose-util.yml ${UTIL_STACK_NAME:-util}
else
    # also deploy the utilities stack if QuantumLeap needs Redis.
    if [ "$FIWARE_INCLUDE_QUANTUMLEAP" == "true" ] && [ "$QL_USE_GEOCODING" == "true" ]
    then
        echo "Deploying the utilities stack2."
        docker stack deploy -c docker-compose-util.yml ${UTIL_STACK_NAME:-util}

        # Since the initializing scripts for postgres container are run only for a new Docker volume,
        # run the database and user creating script separately after the container has started
        docker exec -it $(docker ps | grep ${UTIL_STACK_NAME:-util}_${POSTGRES_SERVICE_URI:-postgresdb} | awk '{print $1}') /docker-entrypoint-initdb.d/create-multiple-postgresql-databases.sh
    fi
fi

if [ "$FIWARE_INCLUDE_GRAFANA" == "true" ]
then
    echo "Deploying Grafana."
    docker stack deploy -c docker-compose-grafana.yml ${GRAFANA_STACK_NAME:-grafana}
fi

if [ "$FIWARE_INCLUDE_WIRECLOUD" == "true" ]
then
    echo "Deploying Wirecloud."
    docker stack deploy -c docker-compose-wirecloud.yml ${WIRECLOUD_STACK_NAME:-wirecloud}
fi

if [ "$FIWARE_INCLUDE_CKAN" == "true" ]
then
    echo "Deploying CKAN."
    docker stack deploy -c docker-compose-ckan.yml ${CKAN_STACK_NAME:-ckan}
fi

##############################################################################
# Deploy the Nginx service using its own script.
##############################################################################

echo "Deploying Nginx proxy server."
source update_nginx.sh
