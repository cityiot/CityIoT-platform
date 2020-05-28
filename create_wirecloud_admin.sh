#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# load enviroment variables
source main_settings.env
source extra_settings.env

WIRECLOUD_ADMIN_USER=$(cat secrets/admins.env | grep WIRECLOUD_ADMIN_USER | cut -d'=' -f2)

echo "Creating $WIRECLOUD_ADMIN_USER as admin user for Wirecloud."
wirecloud_container=$(docker ps | grep ${WIRECLOUD_STACK_NAME:-wirecloud}_${WIRECLOUD_SERVICE_URI:-wirecloud} | awk '{print $1}')

docker exec -it $wirecloud_container python manage.py createsuperuser --username $WIRECLOUD_ADMIN_USER
