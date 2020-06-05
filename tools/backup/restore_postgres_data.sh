#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# Restores the compressed data to the PostgreSQL databases used by Grafana, Wirecloud and CKAN.

if [[ $# -ne 2 ]];
then
    echo "Usage: restore_postgres_data.sh <backup_folder> <platform_folder>"
else
    backup_folder=$1
    platform_folder=$2

    current_folder=$(pwd)
    # this work folder is used to extract all the files, by default it is the /temp/postgres_data subfolder on the calling folder
    work_folder="${current_folder}/temp/postgres_data"

    postgres_config_file=${platform_folder}/env/secrets/postgres.env
    postgres_container=$(docker ps | grep util_postgresdb | awk '{print $1}')

    postgres_main_user=$(cat $postgres_config_file | grep POSTGRES_USER= | cut -d'=' -f2)

    mkdir -p ${work_folder}
    cd ${work_folder}

    latest_postgres_7z_file=$(ls -l --sort=t ${backup_folder}/backup_postgres_data.????-??-??.7z | head -n 1 | awk '{print $NF}')
    7z x ${latest_postgres_7z_file}
    sql_files=$(ls -l | awk '{print $NF}')

    for sql_file in ${sql_files};
    do
        db_name=$(echo "${sql_file}" | cut --delimiter='.' --fields=1)
        docker exec -i ${postgres_container} psql --dbname=${db_name} --username=${postgres_main_user} < ${sql_file}
    done

    rm -rf ${work_folder}/*
    cd ${current_folder}
fi
