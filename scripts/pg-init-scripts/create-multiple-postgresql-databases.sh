#!/bin/bash

# Based on https://github.com/geeckmc/docker-postgresql-multiple-databases/blob/patch-1/create-multiple-postgresql-databases.sh
# which is based on https://github.com/mrts/docker-postgresql-multiple-databases/blob/master/create-multiple-postgresql-databases.sh
# released under MIT License, Copyright (c) 2017 Mart Sõmermaa

# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

set -euo pipefail

function create_database() {
    local database=$1

	echo "Creating database '$database'"
    local pq_db_query=$(psql -v ON_ERROR_STOP=1 --username $POSTGRES_USER --dbname $POSTGRES_DB --tuples-only --command "SELECT 1 FROM pg_database WHERE datname = '$database'")
    local db_exists=$(echo $pq_db_query | grep --quiet 1 || echo "no")
    if [[ $db_exists = "no" ]];
    then
        psql -v ON_ERROR_STOP=1 --username $POSTGRES_USER --dbname $POSTGRES_DB <<-EOSQL
            CREATE DATABASE $database ENCODING 'UTF8';
EOSQL
    else
        echo "Database '$database' already exists."
    fi
}

function create_user() {
    local username=$1
    local password=$2

    echo "Creating user '$username'"
    local pq_user_query=$(psql -v ON_ERROR_STOP=1 --username $POSTGRES_USER --dbname $POSTGRES_DB --tuples-only --command "SELECT 1 FROM pg_user WHERE usename = '$username'")
    local user_exists=$(echo $pq_user_query | grep --quiet 1 || echo "no")
    if [[ $user_exists = "no" ]];
    then
        psql -v ON_ERROR_STOP=1 --username $POSTGRES_USER --dbname $POSTGRES_DB <<-EOSQL
            CREATE USER ${username} WITH PASSWORD '${password}' NOSUPERUSER NOCREATEDB NOCREATEROLE;
EOSQL
    else
        echo "User '$username' already exists."
    fi
}

function grant_access() {
    local database=$1
    local username=$2
    local access_type=$(echo "$3" | awk '{print toupper($0)}')

    echo "Granting user '$username' '$access_type' access to database '$database'"
    if [ $access_type = "WRITE" ];
    then
        psql -v ON_ERROR_STOP=1 --username $POSTGRES_USER --dbname $POSTGRES_DB <<-EOSQL
            GRANT ALL PRIVILEGES ON DATABASE $database TO $username;
EOSQL
    elif [ $access_type = "READ" ];
    then
        psql -v ON_ERROR_STOP=1 --username $POSTGRES_USER --dbname $POSTGRES_DB <<-EOSQL
            GRANT CONNECT, TEMPORARY ON DATABASE $database TO $username;
EOSQL
    else
        echo "Unknown access type: '$access_type'"
    fi
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ];
then
	for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' ');
    do
		create_database $db
	done
fi

if [ -n "$POSTGRES_MULTIPLE_USERS" ];
then
	for userpass in $(echo $POSTGRES_MULTIPLE_USERS | tr ',' ' ');
    do
        user=$(echo $userpass | cut --delimiter=':' --fields=1)
        pass=$(echo $userpass | cut --delimiter=':' --fields=2)
		create_user $user $pass
	done
fi

if [ -n "$POSTGRES_DATABASE_ACCESS" ];
then
	for dbuseraccess in $(echo $POSTGRES_DATABASE_ACCESS | tr ',' ' ');
    do
        db=$(echo $dbuseraccess | cut --delimiter=':' --fields=1)
        user=$(echo $dbuseraccess | cut --delimiter=':' --fields=2)
        access=$(echo $dbuseraccess | cut --delimiter=':' --fields=3)
		grant_access $db $user $access
	done
fi
