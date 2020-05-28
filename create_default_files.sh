#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# load enviroment variables
source main_settings.env
source extra_settings.env

# Create configuration file for Grafana.
current_env_file="env/secrets/grafana.env"
if [ ! -f "$current_env_file" ]
then
    echo "Creating $current_env_file with default parameters."
    cp env/secrets/grafana.env.template $current_env_file
    sed -i "/GF_DATABASE_NAME/c\GF_DATABASE_NAME=grafana" $current_env_file
    sed -i "/GF_DATABASE_USER/c\GF_DATABASE_USER=grafana" $current_env_file
    sed -i "/GF_DATABASE_PASSWORD/c\GF_DATABASE_PASSWORD=grafana" $current_env_file
fi

# Create configuration file for Wirecloud.
current_env_file="env/secrets/wirecloud.env"
if [ ! -f "$current_env_file" ]
then
    echo "Creating $current_env_file with default parameters."
    cp env/secrets/wirecloud.env.template $current_env_file
    sed -i "/DB_NAME/c\DB_NAME=wirecloud" $current_env_file
    sed -i "/DB_USERNAME/c\DB_USERNAME=wirecloud" $current_env_file
    sed -i "/DB_PASSWORD/c\DB_PASSWORD=wirecloud" $current_env_file
fi

# Create configuration file for CKAN.
current_env_file="env/secrets/ckan.env"
if [ ! -f "$current_env_file" ]
then
    echo "Creating $current_env_file with default parameters."
    cp env/secrets/ckan.env.template $current_env_file
    sed -i "/CKAN_POSTGRES_DB/c\CKAN_POSTGRES_DB=ckan" $current_env_file
    sed -i "/CKAN_POSTGRES_USER/c\CKAN_POSTGRES_USER=ckan" $current_env_file
    sed -i "/CKAN_POSTGRES_PASSWORD/c\CKAN_POSTGRES_PASSWORD=ckan" $current_env_file
    sed -i "/DATASTORE_POSTGRES_DB/c\DATASTORE_POSTGRES_DB=datastore" $current_env_file
    sed -i "/DATASTORE_POSTGRES_USER/c\DATASTORE_POSTGRES_USER=datastore" $current_env_file
    sed -i "/DATASTORE_POSTGRES_PASSWORD/c\DATASTORE_POSTGRES_PASSWORD=datastore" $current_env_file
fi

# Create configuration file for PostgreSQL.
current_env_file="env/secrets/postgres.env"
if [ ! -f "$current_env_file" ]
then
    echo "Creating $current_env_file with default parameters."
    cp env/secrets/postgres.env.template $current_env_file
    sed -i "/POSTGRES_USER/c\POSTGRES_USER=cityiot" $current_env_file
    sed -i "/POSTGRES_PASSWORD/c\POSTGRES_PASSWORD=cityiot" $current_env_file
    sed -i "/POSTGRES_DB/c\POSTGRES_DB=cityiot" $current_env_file
fi

# Create configuration file for admin users for Grafana, Wirecloud, and CKAN.
current_env_file="secrets/admins.env"
if [ ! -f "$current_env_file" ]
then
    echo "Creating $current_env_file with default parameters."
    cp secrets/admins_template.env $current_env_file
    sed -i "/GRAFANA_ADMIN_USER/c\GRAFANA_ADMIN_USER=admin" $current_env_file
    sed -i "/GRAFANA_ADMIN_PASSWORD/c\GRAFANA_ADMIN_PASSWORD=admin" $current_env_file
    sed -i "/WIRECLOUD_ADMIN_USER/c\WIRECLOUD_ADMIN_USER=admin" $current_env_file
    sed -i "/CKAN_ADMIN_USER/c\CKAN_ADMIN_USER=admin" $current_env_file
    sed -i "/CKAN_ADMIN_PASSWORD/c\CKAN_ADMIN_PASSWORD=admin" $current_env_file
fi

# Create Nginx configuration file for FIWARE users.
current_conf_file="secrets/users.conf"
if [ ! -f "$current_conf_file" ]
then
    echo "Creating $current_conf_file with default parameters."
    cp secrets/users_template.conf $current_conf_file
    sed -i "/data-provider/c\ " $current_conf_file
    sed -i "/data-viewer/c\ " $current_conf_file
fi

# Create Nginx configuration file for FIWARE services.
current_conf_file="secrets/services.conf"
if [ ! -f "$current_conf_file" ]
then
    echo "Creating $current_conf_file with default parameters."
    cp secrets/services_template.conf $current_conf_file
    sed -i "/data-provider/c\ " $current_conf_file
    sed -i "/data-viewer/c\ " $current_conf_file
fi

# Create Nginx configuration file for FIWARE proxy keys.
current_conf_file="secrets/proxy_keys.conf"
if [ ! -f "$current_conf_file" ]
then
    echo "Creating $current_conf_file with default parameters."
    cp secrets/proxy_keys_template.conf $current_conf_file
    sed -i "/POST/c\ " $current_conf_file
fi
