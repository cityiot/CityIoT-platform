#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

if [[ $# -ne 1 && $# -ne 2 ]];
then
    echo "Usage: backup_crate.sh <backup_folder> [<start_date>]"
else
    current_date=$(date '+%Y-%m-%d')
    output_folder_main=$1
    data_folder=${output_folder_main}/ql_data
    script_folder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

    # load the QuantumLeap metadata table from crate database
    metadata_service=doc
    metadata_table=md_ets_metadata
    source ${script_folder}/backup_crate_table.sh ${metadata_service} ${metadata_table} ${data_folder}
    metadata_filename="${data_folder}/${metadata_service}.${metadata_table}.${current_date}"
    ql_tables=$(cat $metadata_filename.json | awk -F '"table_name":"' '{print $2}' | awk -F '"' '{print $2$4}' | cut --delimiter='\' --output-delimiter '.' --fields=1,2)

    # load the QuantumLeap data from each table
    for table in $ql_tables;
    do
        fiware_service=$(echo "$table" | cut --delimiter="." --fields=1)
        entity_type=$(echo "$table" | cut --delimiter="." --fields=2)
        if [[ $# -eq 2 ]];
        then
            start_date=$2
            source ${script_folder}/backup_crate_table.sh ${fiware_service} ${entity_type} ${data_folder} ${start_date}
        else
            source ${script_folder}/backup_crate_table.sh ${fiware_service} ${entity_type} ${data_folder}
        fi
    done

    # compress the data files with 7-zip
    compressed_file=backup_ql_data.${current_date}.7z
    7z a -t7z -m0=lzma2 -mx=9 ${output_folder_main}/${compressed_file} ${data_folder}/*

    # remove the uncompressed files
    rm ${data_folder}/${metadata_service}.${metadata_table}.${current_date}.json
    rm ${data_folder}/schema/${metadata_service}.${metadata_table}.schema.${current_date}.sql

    for table in $ql_tables;
    do
        fiware_service=$(echo "$table" | cut --delimiter="." --fields=1)
        entity_type=$(echo "$table" | cut --delimiter="." --fields=2)

        if [[ $# -eq 2 ]];
        then
            rm ${data_folder}/${fiware_service}.${entity_type}.${start_date}.${current_date}.json
        else
            rm ${data_folder}/${fiware_service}.${entity_type}.${current_date}.json
        fi

        rm ${data_folder}/schema/${fiware_service}.${entity_type}.schema.${current_date}.sql
    done
fi
