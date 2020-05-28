#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# load enviroment variables
source main_settings.env
source extra_settings.env

CKAN_ADMIN_USER=$(cat secrets/admins.env | grep CKAN_ADMIN_USER | cut -d'=' -f2)
CKAN_ADMIN_PASSWORD=$(cat secrets/admins.env | grep CKAN_ADMIN_PASSWORD | cut -d'=' -f2)

echo "Creating $CKAN_ADMIN_USER as admin user for CKAN."
ckan_container=$(docker ps | grep ${CKAN_STACK_NAME:-ckan}_${CKAN_SERVICE_URI:-ckan}.1. | awk '{print $1}')

helper_script="scripts/ckan_add_admin.sh"
helper_script_file=$(echo "$helper_script" | cut -d'/' -f 2)
helper_script_list=$(docker exec -it $ckan_container ls -l | grep $helper_script_file)
if [ "$helper_script_list" == "" ]
then
    chmod u+x $helper_script
    docker cp $helper_script $ckan_container:.
fi

docker exec -it $ckan_container bash $helper_script_file ${CKAN_ADMIN_USER} ${CKAN_ADMIN_PASSWORD}
