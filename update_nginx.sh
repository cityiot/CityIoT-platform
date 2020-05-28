#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# load enviroment variables
source main_settings.env
source extra_settings.env

# remove the nginx stack
if [ "$(docker stack ls | grep ${NGINX_STACK_NAME:-nginx} | awk '{print $1}')" != "" ]
then
    docker stack rm ${NGINX_STACK_NAME:-nginx}
fi

# start the nginx stack
docker stack deploy -c docker-compose-nginx.yml ${NGINX_STACK_NAME:-nginx}
