#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# load enviroment variables
source main_settings.env
source extra_settings.env

##############################################################################
# Adjust the environment variable files according to the main settings.
##############################################################################

# Create any missing configuration file with default parameters.
source create_default_files.sh

echo "Adjusting environment variable files."
if [ "$QL_USE_GEOCODING" == "true" ]
then
    sed -i "/USE_GEOCODING/c\USE_GEOCODING=True" ./env/quantumleap.env
else
    sed -i "/USE_GEOCODING/c\USE_GEOCODING=False" ./env/quantumleap.env
fi

if [ "$FIWARE_USE_SUBDOMAINS" == "true" ]
then
    if [ "$FIWARE_USE_HTTPS" == "true" ]
    then
        sed -i "/GF_SERVER_ROOT_URL/c\GF_SERVER_ROOT_URL=https://grafana.$DOMAIN_NAME/" ./env/grafana.env
        sed -i "/CKAN_SITE_URL/c\CKAN_SITE_URL=https://ckan.$DOMAIN_NAME" ./env/ckan.env
    else
        sed -i "/GF_SERVER_ROOT_URL/c\GF_SERVER_ROOT_URL=http://grafana.$DOMAIN_NAME/" ./env/grafana.env
        sed -i "/CKAN_SITE_URL/c\CKAN_SITE_URL=http://ckan.$DOMAIN_NAME" ./env/ckan.env
    fi
else
    sed -i "/GF_SERVER_ROOT_URL/c\GF_SERVER_ROOT_URL=http://$DOMAIN_NAME:$GRAFANA_PORT" ./env/grafana.env
    sed -i "/CKAN_SITE_URL/c\CKAN_SITE_URL=http://$DOMAIN_NAME:$CKAN_PORT" ./env/ckan.env
fi

# Creates the proper environment variable strings for env/secrets/ckan.env
CKAN_POSTGRES_DB=$(cat env/secrets/ckan.env | grep CKAN_POSTGRES_DB | cut -d'=' -f2)
CKAN_POSTGRES_USER=$(cat env/secrets/ckan.env | grep CKAN_POSTGRES_USER | cut -d'=' -f2)
CKAN_POSTGRES_PASSWORD=$(cat env/secrets/ckan.env | grep CKAN_POSTGRES_PASSWORD | cut -d'=' -f2)
DATASTORE_POSTGRES_DB=$(cat env/secrets/ckan.env | grep DATASTORE_POSTGRES_DB | cut -d'=' -f2)
DATASTORE_POSTGRES_USER=$(cat env/secrets/ckan.env | grep DATASTORE_POSTGRES_USER | cut -d'=' -f2)
DATASTORE_POSTGRES_PASSWORD=$(cat env/secrets/ckan.env | grep DATASTORE_POSTGRES_PASSWORD | cut -d'=' -f2)

sed -i "/CKAN_DATASTORE_READ_URL/c\CKAN_DATASTORE_READ_URL=postgresql://$DATASTORE_POSTGRES_USER:$DATASTORE_POSTGRES_PASSWORD\@postgresdb/$DATASTORE_POSTGRES_DB" ./env/secrets/ckan.env
sed -i "/CKAN_DATASTORE_WRITE_URL/c\CKAN_DATASTORE_WRITE_URL=postgresql://$CKAN_POSTGRES_USER:$CKAN_POSTGRES_PASSWORD@postgresdb/$DATASTORE_POSTGRES_DB" ./env/secrets/ckan.env
sed -i "/CKAN_SQLALCHEMY_URL/c\CKAN_SQLALCHEMY_URL=postgresql://$CKAN_POSTGRES_USER:$CKAN_POSTGRES_PASSWORD@postgresdb/$CKAN_POSTGRES_DB" ./env/secrets/ckan.env

# Creates the proper environment variable strings for env/secrets/postgres.env
GRAFANA_POSTGRES_DB=$(cat env/secrets/grafana.env | grep GF_DATABASE_NAME | cut -d'=' -f2)
GRAFANA_POSTGRES_USER=$(cat env/secrets/grafana.env | grep GF_DATABASE_USER | cut -d'=' -f2)
GRAFANA_POSTGRES_PASSWORD=$(cat env/secrets/grafana.env | grep GF_DATABASE_PASSWORD | cut -d'=' -f2)

WIRECLOUD_POSTGRES_DB=$(cat env/secrets/wirecloud.env | grep DB_NAME | cut -d'=' -f2)
WIRECLOUD_POSTGRES_USER=$(cat env/secrets/wirecloud.env | grep DB_USERNAME | cut -d'=' -f2)
WIRECLOUD_POSTGRES_PASSWORD=$(cat env/secrets/wirecloud.env | grep DB_PASSWORD | cut -d'=' -f2)

sed -i "/POSTGRES_MULTIPLE_DATABASES/c\POSTGRES_MULTIPLE_DATABASES=$GRAFANA_POSTGRES_DB,$WIRECLOUD_POSTGRES_DB,$CKAN_POSTGRES_DB,$DATASTORE_POSTGRES_DB" ./env/secrets/postgres.env
sed -i "/POSTGRES_MULTIPLE_USERS/c\POSTGRES_MULTIPLE_USERS=$GRAFANA_POSTGRES_USER:$GRAFANA_POSTGRES_PASSWORD,$WIRECLOUD_POSTGRES_USER:$WIRECLOUD_POSTGRES_PASSWORD,$CKAN_POSTGRES_USER:$CKAN_POSTGRES_PASSWORD,$DATASTORE_POSTGRES_USER:$DATASTORE_POSTGRES_PASSWORD" ./env/secrets/postgres.env
sed -i "/POSTGRES_DATABASE_ACCESS/c\POSTGRES_DATABASE_ACCESS=$GRAFANA_POSTGRES_DB:$GRAFANA_POSTGRES_USER:WRITE,$WIRECLOUD_POSTGRES_DB:$WIRECLOUD_POSTGRES_USER:WRITE,$CKAN_POSTGRES_DB:$CKAN_POSTGRES_USER:WRITE,$DATASTORE_POSTGRES_DB:$DATASTORE_POSTGRES_USER:READ" ./env/secrets/postgres.env

# Updates the Grafana admin user settings to env/secrets/grafana.env
GRAFANA_ADMIN_USER=$(cat secrets/admins.env | grep GRAFANA_ADMIN_USER | cut -d'=' -f2)
GRAFANA_ADMIN_PASSWORD=$(cat secrets/admins.env | grep GRAFANA_ADMIN_PASSWORD | cut -d'=' -f2)

sed -i "/GF_SECURITY_ADMIN_USER/c\GF_SECURITY_ADMIN_USER=$GRAFANA_ADMIN_USER" ./env/secrets/grafana.env
sed -i "/GF_SECURITY_ADMIN_PASSWORD/c\GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASSWORD" ./env/secrets/grafana.env

##############################################################################
# Adjust the Nginx configuration files according to the main settings.
##############################################################################

echo "Adjusting Nginx configuration files."
if [ "$FIWARE_USE_SUBDOMAINS" == "true" ]
then
    if [ "$FIWARE_USE_HTTPS" == "true" ]
    then
        sed -i "/main_subdomain_https.conf/c\include servers/main_subdomain_https.conf;" ./nginx/servers.conf
        sed -i "/main_subdomain_http.conf/c\# include servers/main_subdomain_http.conf;" ./nginx/servers.conf
        sed -i "/main_port.conf/c\# include servers/main_port.conf;" ./nginx/servers.conf
    else
        sed -i "/main_subdomain_https.conf/c\# include servers/main_subdomain_https.conf;" ./nginx/servers.conf
        sed -i "/main_subdomain_http.conf/c\include servers/main_subdomain_http.conf;" ./nginx/servers.conf
        sed -i "/main_port.conf/c\# include servers/main_port.conf;" ./nginx/servers.conf
    fi
else
    sed -i "/main_subdomain_https.conf/c\# include servers/main_subdomain_https.conf;" ./nginx/servers.conf
    sed -i "/main_subdomain_http.conf/c\# include servers/main_subdomain_http.conf;" ./nginx/servers.conf
    sed -i "/main_port.conf/c\include servers/main_port.conf;" ./nginx/servers.conf
fi

if [ "$FIWARE_INCLUDE_QUANTUMLEAP" == "true" ]
then
    sed -i "/quantumleap_component.conf/c\include components/quantumleap_component.conf;" ./nginx/servers/main_locations_common.conf
else
    sed -i "/quantumleap_component.conf/c\# include components/quantumleap_component.conf;" ./nginx/servers/main_locations_common.conf
fi

if [ "$FIWARE_INCLUDE_IOTAGENT_UL" == "true" ]
then
    sed -i "/iotagent_ul_component.conf/c\include components/iotagent_ul_component.conf;" ./nginx/servers/main_locations_common.conf
else
    sed -i "/iotagent_ul_component.conf/c\# include components/iotagent_ul_component.conf;" ./nginx/servers/main_locations_common.conf
fi

# Change the host names in the configurations.
sed -i "/server_name/c\    server_name $DOMAIN_NAME;" ./nginx/servers/main_port.conf
sed -i "/server_name/c\    server_name $DOMAIN_NAME;" ./nginx/servers/main_subdomain_http.conf
sed -i "/server_name/c\    server_name $DOMAIN_NAME;" ./nginx/servers/main_subdomain_https.conf

sed -i "/rewrite/c\        rewrite ^(.*) https://$DOMAIN_NAME$1 permanent;" ./nginx/servers/main_subdomain_https.conf
sed -i "/rewrite/c\    rewrite ^(.*) http://$DOMAIN_NAME permanent;" ./nginx/servers/other/other_subdomain_http.conf
sed -i "/rewrite/c\    rewrite ^(.*) https://$DOMAIN_NAME permanent;" ./nginx/servers/other/other_subdomain_https.conf

sed -i "/orion\/v2\/op\/notify/c\    proxy_pass \$scheme://$DOMAIN_NAME/orion/v2/op/notify;" ./nginx/components/orion_component.conf


subdomain_names="keyrock grafana wirecloud ckan"

for subdomain_name in $subdomain_names;
do
    case "$subdomain_name" in
        grafana)
            include_subdomain=$FIWARE_INCLUDE_GRAFANA
            subdomain_port=$GRAFANA_PORT
            ;;
        wirecloud)
            include_subdomain=$FIWARE_INCLUDE_WIRECLOUD
            subdomain_port=$WIRECLOUD_PORT
            ;;
        ckan)
            include_subdomain=$FIWARE_INCLUDE_CKAN
            subdomain_port=$CKAN_PORT
            ;;
        keyrock)
            include_subdomain=$FIWARE_INCLUDE_ACCESS_CONTROL
            subdomain_port=$KEYROCK_PORT
            ;;
    esac

    if [ "$include_subdomain" == "true" ]
    then
        subdomain_include_start=""
    else
        subdomain_include_start="# "
    fi

    # Pick the correct include sentence for server configuration.
    sed -i "/${subdomain_name}_subdomain_https.conf/c\ ${subdomain_include_start}include servers/${subdomain_name}/${subdomain_name}_subdomain_https.conf;" ./nginx/servers/main_subdomain_https.conf
    sed -i "/${subdomain_name}_subdomain_http.conf/c\ ${subdomain_include_start}include servers/${subdomain_name}/${subdomain_name}_subdomain_http.conf;" ./nginx/servers/main_subdomain_http.conf
    sed -i "/${subdomain_name}_port.conf/c\ ${subdomain_include_start}include servers/${subdomain_name}/${subdomain_name}_port.conf;" ./nginx/servers/main_port.conf

    sed -i "/${subdomain_name}_subdomain.conf/c\ ${subdomain_include_start}include components/${subdomain_name}/${subdomain_name}_subdomain.conf;" ./nginx/servers/main_locations_subdomain.conf
    sed -i "/${subdomain_name}_port.conf/c\ ${subdomain_include_start}include components/${subdomain_name}/${subdomain_name}_port.conf;" ./nginx/servers/main_locations_port.conf

    # Change the host names in the configurations.
    sed -i "/server_name ${subdomain_name}/c\    server_name ${subdomain_name}.$DOMAIN_NAME;" ./nginx/acme-challenge_subdomains.conf
    sed -i "/server_name ${subdomain_name}/c\    server_name ${subdomain_name}.$DOMAIN_NAME;" ./nginx/servers/${subdomain_name}/${subdomain_name}_subdomain_https.conf
    sed -i "/server_name ${subdomain_name}/c\    server_name ${subdomain_name}.$DOMAIN_NAME;" ./nginx/servers/${subdomain_name}/${subdomain_name}_subdomain_http.conf

    sed -i "/server_name/c\    server_name $DOMAIN_NAME;" ./nginx/servers/${subdomain_name}/${subdomain_name}_port.conf

    sed -i "/rewrite/c\        rewrite ^(.*) https://${subdomain_name}.$DOMAIN_NAME$1 permanent;" ./nginx/servers/${subdomain_name}/${subdomain_name}_subdomain_https.conf

    sed -i "/rewrite/c\    rewrite ^/${subdomain_name}(.*) \$scheme://${subdomain_name}.$DOMAIN_NAME$1 permanent;" ./nginx/components/${subdomain_name}/${subdomain_name}_subdomain.conf
    sed -i "/rewrite/c\    rewrite ^/${subdomain_name}(.*) http://$DOMAIN_NAME:${subdomain_port}$1 permanent;" ./nginx/components/${subdomain_name}/${subdomain_name}_port.conf
done

# Change the host name in the index.html
if [ "$FIWARE_USE_HTTPS" == "true" ]
then
    domain_address="https://$DOMAIN_NAME"
else
    domain_address="http://$DOMAIN_NAME"
fi

sed -i "/orion\/\"/c\                <a href=\"$domain_address/orion/\"><strong>$domain_address/orion/</strong></a>" ./nginx/html/index.html
sed -i "/orion\/version/c\                    <li>Version check: <a href=\"$domain_address/orion/version\">version check</a></li>" ./nginx/html/index.html

sed -i "/quantumleap\/\"/c\                <a href=\"$domain_address/quantumleap/\"><strong>$domain_address/quantumleap/</strong></a>" ./nginx/html/index.html
sed -i "/quantumleap\/version/c\                    <li>Version check: <a href=\"$domain_address/quantumleap/version/\">version check</a></li>" ./nginx/html/index.html

sed -i "/grafana\//c\                <a href=\"$domain_address/grafana/\"><strong>$domain_address/grafana/</strong></a>" ./nginx/html/index.html

sed -i "/wirecloud\//c\                <a href=\"$domain_address/wirecloud/\"><strong>$domain_address/wirecloud/</strong></a>" ./nginx/html/index.html

sed -i "/ckan\//c\                <a href=\"$domain_address/ckan/\"><strong>$domain_address/ckan/</strong></a>" ./nginx/html/index.html

##############################################################################
# Adjust the Docker Compose files according to the main settings.
##############################################################################

echo "Adjusting Docker Compose files."
if [ "$FIWARE_USE_SUBDOMAINS" == "true" ]
then
    sed -i "/ports:/c\    # ports:" ./docker-compose-grafana.yml
    sed -i "/- target/c\    #   - target: \${GRAFANA_PORT:-3000}" ./docker-compose-grafana.yml
    sed -i "/published:/c\    #     published: \${GRAFANA_PORT:-3000}" ./docker-compose-grafana.yml
    sed -i "/protocol:/c\    #     protocol: tcp" ./docker-compose-grafana.yml
    sed -i "/mode:/c\    #     mode: host" ./docker-compose-grafana.yml

    sed -i "/ports:/c\    # ports:" ./docker-compose-wirecloud.yml
    sed -i "/- target/c\    #   - target: \${WIRECLOUD_PORT:-8000}" ./docker-compose-wirecloud.yml
    sed -i "/published:/c\    #     published: \${WIRECLOUD_PORT:-8000}" ./docker-compose-wirecloud.yml
    sed -i "/protocol:/c\    #     protocol: tcp" ./docker-compose-wirecloud.yml
    sed -i "/mode:/c\    #     mode: host" ./docker-compose-wirecloud.yml

    sed -i "/ports:/c\    # ports:" ./docker-compose-ckan.yml
    sed -i "/- target/c\    #   - target: \${CKAN_PORT:-5000}" ./docker-compose-ckan.yml
    sed -i "/published:/c\    #     published: \${CKAN_PORT:-5000}" ./docker-compose-ckan.yml
    sed -i "/protocol:/c\    #     protocol: tcp" ./docker-compose-ckan.yml
    sed -i "/mode:/c\    #     mode: host" ./docker-compose-ckan.yml
else
    sed -i "/ports:/c\    ports:" ./docker-compose-grafana.yml
    sed -i "/- target/c\      - target: \${GRAFANA_PORT:-3000}" ./docker-compose-grafana.yml
    sed -i "/published:/c\        published: \${GRAFANA_PORT:-3000}" ./docker-compose-grafana.yml
    sed -i "/protocol:/c\        protocol: tcp" ./docker-compose-grafana.yml
    sed -i "/mode:/c\        mode: host" ./docker-compose-grafana.yml

    sed -i "/ports:/c\    ports:" ./docker-compose-wirecloud.yml
    sed -i "/- target/c\      - target: \${WIRECLOUD_PORT:-8000}" ./docker-compose-wirecloud.yml
    sed -i "/published:/c\        published: \${WIRECLOUD_PORT:-8000}" ./docker-compose-wirecloud.yml
    sed -i "/protocol:/c\        protocol: tcp" ./docker-compose-wirecloud.yml
    sed -i "/mode:/c\        mode: host" ./docker-compose-wirecloud.yml

    sed -i "/ports:/c\    ports:" ./docker-compose-ckan.yml
    sed -i "/- target/c\      - target: \${CKAN_PORT:-5000}" ./docker-compose-ckan.yml
    sed -i "/published:/c\        published: \${CKAN_PORT:-5000}" ./docker-compose-ckan.yml
    sed -i "/protocol:/c\        protocol: tcp" ./docker-compose-ckan.yml
    sed -i "/mode:/c\        mode: host" ./docker-compose-ckan.yml
fi

sed -i '/target: 443/d' ./docker-compose-nginx.yml
sed -i '/published:/d' ./docker-compose-nginx.yml
sed -i '/mode: host/d' ./docker-compose-nginx.yml
sed -i '/protocol: tcp/d' ./docker-compose-nginx.yml
if [ "$FIWARE_USE_HTTPS" == "true" ]
then
    sed -i "/- certificate/c\      - certificate" ./docker-compose-nginx.yml
    sed -i "/- dhparams/c\      - dhparams" ./docker-compose-nginx.yml
    sed -i "/- private_key/c\      - private_key" ./docker-compose-nginx.yml
    sed -i "/certificate:/c\  certificate:" ./docker-compose-nginx.yml
    sed -i "/chained.pem/c\    file: ./secrets/chained.pem" ./docker-compose-nginx.yml
    sed -i "/dhparams:/c\  dhparams:" ./docker-compose-nginx.yml
    sed -i "/dhparam.pem/c\    file: ./secrets/dhparam.pem" ./docker-compose-nginx.yml
    sed -i "/private_key:/c\  private_key:" ./docker-compose-nginx.yml
    sed -i "/domain.key/c\    file: ./secrets/domain.key" ./docker-compose-nginx.yml

    sed -i "/- target: 80/c\      - target: 80\n        published: 80\n        mode: host\n        protocol: tcp\n      - target: 443\n        published: 443\n        mode: host\n        protocol: tcp" ./docker-compose-nginx.yml
else
    sed -i "/- certificate/c\    # - certificate" ./docker-compose-nginx.yml
    sed -i "/- dhparams/c\    # - dhparams" ./docker-compose-nginx.yml
    sed -i "/- private_key/c\    # - private_key" ./docker-compose-nginx.yml
    sed -i "/certificate:/c\# certificate:" ./docker-compose-nginx.yml
    sed -i "/chained.pem/c\#   file: ./secrets/chained.pem" ./docker-compose-nginx.yml
    sed -i "/dhparams:/c\# dhparams:" ./docker-compose-nginx.yml
    sed -i "/dhparam.pem/c\#   file: ./secrets/dhparam.pem" ./docker-compose-nginx.yml
    sed -i "/private_key:/c\# private_key:" ./docker-compose-nginx.yml
    sed -i "/domain.key/c\#   file: ./secrets/domain.key" ./docker-compose-nginx.yml

    sed -i "/- target: 80/c\      - target: 80\n        published: 80\n        mode: host\n        protocol: tcp\n    # - target: 443\n    #   published: 443\n    #   mode: host\n    #   protocol: tcp" ./docker-compose-nginx.yml
fi
