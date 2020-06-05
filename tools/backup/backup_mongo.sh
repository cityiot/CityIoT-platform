#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

current_date=$(date '+%Y-%m-%d')
output_folder=$1
data_folder=${output_folder}/orion_data

# create mongodump from which the database can be restored by mongorestore
mongo_container=$(docker ps | grep mongodb | awk '{print $1}')
docker exec -it ${mongo_container} mongodump

# get the list of databases
mongo_dump_folder=dump
mongo_user=root
mongo_databases=$(docker exec -it ${mongo_container} ls -l /${mongo_dump_folder} | grep ${mongo_user} | awk '{print $NF}')

# copy all the files from mongodump to local folder
for mongo_database in ${mongo_databases};
do
    mongo_folder=${mongo_dump_folder}/${mongo_database::-1}
    database_files=$(docker exec -it ${mongo_container} ls -l /${mongo_folder} | grep ${mongo_user} | awk '{print $NF}')

    local_folder=${data_folder}/${mongo_database::-1}
    mkdir -p ${local_folder}

    for database_file in ${database_files};
    do
        docker cp ${mongo_container}:/${mongo_folder}/${database_file::-1} ${local_folder}
    done
done

# compress the data files with 7-zip
compressed_file=backup_orion_data.${current_date}.7z
7z a -t7z -m0=lzma2 -mx=9 ${output_folder}/${compressed_file} ${data_folder}/*

# remove the uncompressed files
for mongo_database in ${mongo_databases};
do
    local_folder=${data_folder}/${mongo_database::-1}
    local_files=$(ls -l ${local_folder} | grep ${USER} | awk '{print $NF}')
    for local_file in ${local_files};
    do
        rm ${local_folder}/${local_file}
    done
done
