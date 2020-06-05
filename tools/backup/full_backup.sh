#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

if [[ $# -ne 2 && $# -ne 3 ]];
then
    echo "Usage: full_backup.sh <platform_folder> <backup_folder> [--update | <start_date>]"
else
    platform_folder=$1
    backup_folder=$2
    script_folder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

    # backup the full Mongo database that Orion uses
    source ${script_folder}/backup_mongo.sh ${backup_folder}

    # backup the full Postgres databases that Grafana, Wirecloud and CKAN uses
    source ${script_folder}/backup_postgres.sh ${backup_folder} ${platform_folder}

    # backup the configuration files
    source ${script_folder}/backup_config.sh ${backup_folder} ${platform_folder}

    # backup the Crate database that QuantumLeap uses
    if [[ $# -eq 3 ]];
    then
        if [ $3 = "--update" ];
        then
            backup_file_identifier=7z
            ql_backup_identifier=backup_ql_data

            # deternmine the start date from the files in the backup folder.
            start_date=$(ls -l --sort=t ${backup_folder}/*.${backup_file_identifier} | grep ${ql_backup_identifier} | awk '{print $NF}' | cut --delimiter='.' --fields=2 | head -n 1)
        else
            # use the second function parameter as the start date
            start_date=$3
        fi
        source ${script_folder}/backup_crate.sh ${backup_folder} ${start_date}
    else
        source ${script_folder}/backup_crate.sh ${backup_folder}
    fi
fi
