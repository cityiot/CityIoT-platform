#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

current_date=$(date '+%Y-%m-%d')
output_folder=$1
platform_folder=$2
data_folder=${output_folder}/postgres_data
mkdir -p ${data_folder}

postgres_config_file=${platform_folder}/env/secrets/postgres.env
postgres_container=$(docker ps | grep util_postgresdb | awk '{print $1}')

postgres_main_user=$(cat $postgres_config_file | grep POSTGRES_USER= | cut -d'=' -f2)
postgres_main_database=$(cat $postgres_config_file | grep POSTGRES_DB= | cut -d'=' -f2)
postgres_app_databases=$(cat $postgres_config_file | grep POSTGRES_MULTIPLE_DATABASES= | cut -d'=' -f2)

postgres_databases=$(echo "${postgres_main_database},${postgres_app_databases}" | tr , ' ')

for postgres_database in ${postgres_databases};
do
    echo "$postgres_database"
    docker exec -it ${postgres_container} pg_dump --clean --if-exists --column-inserts ${postgres_database} -U ${postgres_main_user} > ${data_folder}/${postgres_database}.sql
done

# compress the data files with 7-zip
compressed_file=backup_postgres_data.${current_date}.7z
7z a -t7z -m0=lzma2 -mx=9 ${output_folder}/${compressed_file} ${data_folder}/*

# remove the uncompressed files
for postgres_database in ${postgres_databases};
do
    rm ${data_folder}/${postgres_database}.sql
done
