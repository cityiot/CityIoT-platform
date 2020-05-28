#!/bin/bash
# Copyright 2020 Tampere University
# This software was developed as a part of the CityIoT project: https://www.cityiot.fi/english
# This source code is licensed under the 3-clause BSD license. See license.txt in the repository root directory.
# Author(s): Ville Heikkilä <ville.heikkila@tuni.fi>

# Helper script for adding a CKAN superuser.

. /usr/lib/ckan/default/bin/activate
cd /usr/lib/ckan/default/src/ckan
echo "paster sysadmin add $1 password=$2 -c /etc/ckan/default/production.ini"
paster sysadmin add $1 password=$2 -c /etc/ckan/default/production.ini
