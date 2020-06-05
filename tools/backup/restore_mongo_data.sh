#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# Restores the compressed data to the Mongo database.

if [[ $# -ne 1 ]];
then
    echo "Usage: restore_crate_data.sh <backup_folder>"
else
    backup_folder=$1
    current_folder=$(pwd)
    # this work folder is used to extract all the files, by default it is the /temp/mongodump subfolder on the calling folder
    work_folder="${current_folder}/temp/mongodump"

    mongo_container=$(docker ps | grep mongodb | awk '{print $1}')
    mongo_volume=mongo_data
    mongo_volume_folder=$(docker volume inspect ${mongo_volume} | grep Mountpoint | awk '{print $NF}' | cut --delimiter='"' --fields=2)
    mongo_volume_base_folder=/data/db
    mongodump_folder_in_container=/backup/mongodump

    mkdir -p ${work_folder}
    cd ${work_folder}

    latest_mongo_7z_file=$(ls -l --sort=t ${backup_folder}/backup_orion_data.????-??-??.7z | head -n 1 | awk '{print $NF}')

    docker exec -it ${mongo_container} mkdir -p ${mongo_volume_base_folder}${mongodump_folder_in_container}
    7z x ${latest_mongo_7z_file}
    cp -rp ${work_folder}/* ${mongo_volume_folder}${mongodump_folder_in_container}
    rm -rf ${work_folder}/*

    docker exec -it ${mongo_container} mongorestore --drop ${mongo_volume_base_folder}${mongodump_folder_in_container}

    rm -rf ${mongo_volume_folder}${mongodump_folder_in_container}/*

    cd ${current_folder}
fi
