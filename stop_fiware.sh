#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# This script stops all the CityIoT FIWARE platform services.

# load enviroment variables
source extra_settings.env

fiware_stack_names="${NGINX_STACK_NAME:-nginx} ${CKAN_STACK_NAME:-ckan} ${WIRECLOUD_STACK_NAME:-wirecloud} ${GRAFANA_STACK_NAME:-grafana} ${UTIL_STACK_NAME:-util} ${IOTAGENT_UL_STACK_NAME:-iotagent} ${QL_STACK_NAME:-ql} ${ORION_STACK_NAME:-orion} ${MONGO_STACK_NAME:-mongo-rs}"

for stack_name in $fiware_stack_names
do
    container_list=$(docker stack ls | grep $stack_name)
    if [ "$container_list" != "" ]
    then
        docker stack rm $stack_name
    fi
done
