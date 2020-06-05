#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

if [[ $# -ne 3 && $# -ne 4 ]];
then
    echo "Illegal number of parameters"
else
    fiware_service=$1
    entity_type=$2
    output_folder=$3
    current_date=$(date '+%Y-%m-%d')
    crate_folder="data"

    if [[ $# -eq 4 ]];
    then
        start_date=$4
        sql_command="COPY ${fiware_service}.${entity_type} WHERE time_index >= '${start_date}T00:00:00Z' TO DIRECTORY '/${crate_folder}' WITH (format=json_object);"
        output_filename="${output_folder}/${fiware_service}.${entity_type}.${start_date}.${current_date}"
    else
        sql_command="COPY ${fiware_service}.${entity_type} TO DIRECTORY '/${crate_folder}' WITH (format=json_object);"
        output_filename="${output_folder}/${fiware_service}.${entity_type}.${current_date}";
    fi

    mkdir -p ${output_folder}/schema

    # fetch the table data from crate database
    crate_container=$(docker ps | grep cratedb | awk '{print $1}')
    docker exec -it ${crate_container} crash --command "${sql_command}"
    docker exec -it ${crate_container} ls -l /${crate_folder} | grep ${entity_type}_ | grep _.json | awk '{print $NF}'

    # copy the table data to a single file
    docker cp ${crate_container}:/${crate_folder}/${entity_type}_0_.json ${output_filename}._0_.json
    docker cp ${crate_container}:/${crate_folder}/${entity_type}_1_.json ${output_filename}._1_.json
    docker cp ${crate_container}:/${crate_folder}/${entity_type}_2_.json ${output_filename}._2_.json
    docker cp ${crate_container}:/${crate_folder}/${entity_type}_3_.json ${output_filename}._3_.json
    cat ${output_filename}._?_.json > ${output_filename}.json
    rm ${output_filename}._?_.json

    # remove the data files from the crate container
    docker exec -it ${crate_container} rm /${crate_folder}/${entity_type}_0_.json
    docker exec -it ${crate_container} rm /${crate_folder}/${entity_type}_1_.json
    docker exec -it ${crate_container} rm /${crate_folder}/${entity_type}_2_.json
    docker exec -it ${crate_container} rm /${crate_folder}/${entity_type}_3_.json

    # load the table schema from the database and format the result
    schema_command="SHOW CREATE TABLE ${fiware_service}.${entity_type};"
    schema_first_line="CREATE TABLE IF NOT EXISTS "$fiware_service"."$entity_type" ("
    schema_last_line=";"
    schema_filename="${output_folder}/schema/${fiware_service}.${entity_type}.schema.${current_date}.sql"

    docker exec -it ${crate_container} crash --command "${schema_command}" --format mixed | tail -n +2 > $schema_filename
    sed -i "1s/.*/$schema_first_line/" $schema_filename
    head -n -4 $schema_filename > $schema_filename.temp
    mv $schema_filename.temp $schema_filename
    echo "$schema_last_line" >> $schema_filename
fi
