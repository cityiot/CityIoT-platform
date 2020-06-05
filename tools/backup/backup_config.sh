#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

current_date=$(date '+%Y-%m-%d')
output_folder=$1
platform_folder=$2
data_folder=${output_folder}/config_data

# create the needed backup folders if they don't already exist
mkdir -p ${data_folder}/secrets
mkdir -p ${data_folder}/env/secrets

# copy the configurations files to the backup data folder
cp ${platform_folder}/*.env ${data_folder}
cp ${platform_folder}/*.yml ${data_folder}
cp ${platform_folder}/secrets/*.conf ${data_folder}/secrets
cp ${platform_folder}/secrets/*.env ${data_folder}/secrets
cp ${platform_folder}/env/*.env ${data_folder}/env
cp ${platform_folder}/env/secrets/*.env ${data_folder}/env/secrets

# compress the data files with 7-zip
compressed_file=backup_config_data.${current_date}.7z
7z a -t7z -m0=lzma2 -mx=9 ${output_folder}/${compressed_file} ${data_folder}/*

# remove the uncompressed files from the backup data folder
rm ${data_folder}/*.env
rm ${data_folder}/*.yml
rm ${data_folder}/secrets/*.conf
rm ${data_folder}/secrets/*.env
rm ${data_folder}/env/*.env
rm ${data_folder}/env/secrets/*.env
