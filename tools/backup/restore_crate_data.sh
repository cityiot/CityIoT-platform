#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# Restores the compressed data to the Crate database.
# Also, created the database tables if the --update_schemas option is given.

if [[ $# -ne 1 && $# -ne 2 ]];
then
    echo "Usage: restore_crate_data.sh <backup_folder> [--update_schemas]"
else
    backup_folder=$1
    current_folder=$(pwd)
    # this work folder is used to extract all the files, by default it is the /temp subfolder on the calling folder
    work_folder="${current_folder}/temp"

    crate_volume=crate_data
    crate_volume_folder=$(docker volume inspect ${crate_volume} | grep Mountpoint | awk '{print $NF}' | cut --delimiter='"' --fields=2)
    db_folder_inside_crate=/data
    crate_container=$(docker ps | grep ql_cratedb | awk '{print $1}')

    if [[ $# -eq 2 ]];
    then
        if [ $2 = "--update_schemas" ];
        then
            cd ${work_folder}
            newest_7z_file=$(ls -l --sort=t ${backup_folder}/backup_ql_data.????-??-??.7z | head -n 1 | awk '{print $NF}')
            schema_files=$(7z l $newest_7z_file | grep schema/ | awk '{print $NF}')

            for schema_file in ${schema_files};
            do
                schema_filename_only=$(echo "${schema_file}" | rev | cut --delimiter='/' --fields=1 | rev)

                7z x ${newest_7z_file} ${schema_file}
                mv ${schema_file} ${crate_volume_folder}

                docker exec -it ${crate_container} crash --command "\r ${schema_filename_only}"

                rm ${crate_volume_folder}/${schema_filename_only}
            done
        else
            echo "Usage: restore_crate_data.sh <backup_folder> [--update_schemas]"
        fi
    fi

    cd ${work_folder}
    crate_7z_files=$(ls -l --sort=t --reverse ${backup_folder}/backup_ql_data.????-??-??.7z | awk '{print $NF}')

    for crate_7z_file in ${crate_7z_files};
    do
        data_files=$(7z l $crate_7z_file | grep json | awk '{print $NF}')

        for data_file in ${data_files};
        do
            data_filename_only=$(echo "${data_file}" | rev | cut --delimiter='/' --fields=1 | rev)
            fiware_service=$(echo "${data_filename_only}" | cut --delimiter='.' --fields=1)
            entity_type=$(echo "${data_filename_only}" | cut --delimiter='.' --fields=2)

            7z x ${crate_7z_file} ${data_file}
            mv ${data_file} ${crate_volume_folder}

            sql_command="COPY ${fiware_service}.${entity_type} FROM '${db_folder_inside_crate}/${data_filename_only}';"
            docker exec -it ${crate_container} crash --command "${sql_command}"

            rm ${crate_volume_folder}/${data_filename_only}
        done
    done

    cd ${current_folder}
fi
