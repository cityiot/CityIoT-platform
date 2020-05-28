#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# This file contains notes on how to get CKAN with Fiware extensions working.

# Command to deploy the CKAN stack. Note that the util stack is also needed for CKAN to work.
docker stack deploy -c docker-compose-ckan.yml ckan

# If CKAN does not start properly or it has crashed, restart ckan container with the following commands.
docker service rm ckan_ckan
docker stack deploy -c docker-compose-ckan.yml ckan

##################################################################
# Enabling CKAN FIWARE extensios
##################################################################

# Enter the CKAN container
docker exec -it $(docker ps | grep ckan_ckan.1 | awk '{print $NF}') bash

# while inside the ckan container
. /usr/lib/ckan/default/bin/activate
pip install ckanext-oauth2==0.7.0
pip install ckanext-privatedatasets==0.4
pip install ckanext-right_time_context==0.9
pip install ckanext-baepublisher==0.5
pip install ckanext-wirecloud_view==1.1.0
pip install ckanext-datarequests==1.1.0

production_file='/etc/ckan/default/production.ini'
ckan_site='https://ckan.tlt-cityiot.rd.tuni.fi'
ckan_path=''
new_plugins='datastore datapusher resource_proxy right_time_context privatedatasets datarequests'
new_views='right_time_context'

# to remove the default superuser
cd /usr/lib/ckan/default/src/ckan
paster sysadmin remove default -c "$production_file"

# set the site url and path
sed -i "/ckan.site_url/c\ckan.site_url = $ckan_site" "$production_file"
sed -i "/ckan.root_path/c\ckan.root_path = $ckan_path" "$production_file"

# if the ckan.root_path option does not exist in the ini-file, use the following instead
sed -i "/ckan.site_url/c\ckan.site_url = $ckan_site\nckan.root_path = $ckan_path" "$production_file"

# add the plugins and views to the settings
sed -i "s/ckan.plugins =/ckan.plugins = $new_plugins/" "$production_file"
sed -i "s/ckan.views.default_views =/ckan.views.default_views = $new_views/" "$production_file"

##################################################################

# do the following outside the CKAN container to restart CKAN
docker service rm ckan_ckan
docker stack deploy -c docker-compose-ckan.yml ckan

# this can be tried to suppress "Could not reliably determine the server's fully qualified domain name" message
docker exec -it $(docker ps | grep ckan_ckan.1 | awk '{print $1}') sed -i -e "\$aServerName localhost" /etc/apache2/apache2.conf

# if there is a problem with database authentication for user datastore_ro
# (seen with: docker service logs ckan_ckan)
# ckan_pg_container=$(docker ps | grep ckan_postgres | awk '{print $NF}')
# docker exec -it $ckan_pg_container psql -v ON_ERROR_STOP=1 --username ckan
# DROP ROLE datastore_ro;
# CREATE ROLE datastore_ro NOSUPERUSER NOCREATEDB NOCREATEROLE LOGIN PASSWORD 'datastore';
# \q
# docker service rm ckan_ckan
# docker stack deploy -c docker-compose-ckan.yml ckan

# the ckan should be available at http://ckan:5000 inside the docker network
# for FIWARE NGSI datasets use the format: fiware-ngsi
# user documentation at https://github.com/conwetlab/FIWARE-CKAN-Extensions/blob/master/doc/user-programmer-guide.rst
