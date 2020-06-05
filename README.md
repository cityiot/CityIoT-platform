# CityIoT FIWARE platform

The goal of the [CityIoT project](https://www.cityiot.fi/english) is to define a vendor independent IoT platform for SmartCity applications. [FIWARE](https://www.fiware.org) was selected as the technical framework, because it has similar goals towards vendor independence and has already gained interest in the SmartCity community. FIWARE offers open source components for building a platform for smart applications. This repository contains the CityIoT FIWARE platform code that anyone can use to setup their own FIWARE platform. There a few options that can chosen to affect on how the platform is deployed and which components are included in the platform.

A document regarding the CityIoT FIWARE platform and its various technical details: [Report on FIWARE Platform](https://drive.google.com/file/d/1yueGrdArlFmz8ZzchTXWuhbgC9dKUuGN). The installation instructions for the platform can be found in this file.

Table of Contents
- [CityIoT FIWARE platform](#cityiot-fiware-platform)
  - [Platform architecture](#platform-architecture)
  - [Deployment instructions](#deployment-instructions)
    - [System requirements](#system-requirements)
    - [Choosing the deployment options (step 1)](#choosing-the-deployment-options-step-1)
    - [Choosing the database settings (step 2)](#choosing-the-database-settings-step-2)
    - [Choosing the admin usernames and passwords (step 3)](#choosing-the-admin-usernames-and-passwords-step-3)
    - [Setting the Nginx access control permission (step 4)](#setting-the-nginx-access-control-permission-step-4)
    - [Getting the SSL certificate (step 5)](#getting-the-ssl-certificate-step-5)
    - [Installing the platform (step 6)](#installing-the-platform-step-6)
    - [Adding admin user to Wirecloud and CKAN (step 7)](#adding-admin-user-to-wirecloud-and-ckan-step-7)
    - [Uninstalling the platform](#uninstalling-the-platform)
  - [Platform usage instructions](#platform-usage-instructions)
    - [Orion Context Broker](#orion-context-broker)
    - [QuantumLeap](#quantumleap)
    - [IoT Agent for the Ultralight 2.0](#iot-agent-for-the-ultralight-20)
    - [Grafana, Wirecloud, and CKAN](#grafana-wirecloud-and-ckan)
  - [Platform management](#platform-management)
    - [Updating deployment options](#updating-deployment-options)
    - [Updating Nginx access control permissions](#updating-nginx-access-control-permissions)
    - [Updating SSL certificate](#updating-ssl-certificate)
    - [Scaling the components](#scaling-the-components)
    - [Backing and restoring data](#backing-and-restoring-data)
    - [Memory issue with Orion](#memory-issue-with-orion)

## Platform architecture

The FIWARE platform is composed of several FIWARE services with the access control management handled by Nginx server.
All services have been made available using Docker containers.
A single-node Docker swarm is used to make the scaling of some of the services easier.

All the FIWARE services are accessed through Nginx proxy server with each service having its own address path.
The Nginx server handles the communication encryption using TLS as well as load balancing using cache for queries.
A FIWARE service based access control is also handled by the Nginx server.

![CityIoT FIWARE platform architecture diagram](nginx/html/cityiot_platform_architecture.png)

Available services (only Orion is a mandatory part of a FIWARE platform, all other services are optional but are included by default in the CityIoT FIWARE platform):

- [Orion Context Broker](https://fiware-orion.rtfd.io/) (version 2.3.0)
  - The core FIWARE Generic Enabler that provides [FIWARE NGSIv2 API](http://fiware.github.io/specifications/ngsiv2/stable/).
  - Uses Mongo database to store the data.
  - Uses FIWARE service based access control (provided by the custom Nginx server rules).
  - By default 5 replicas are running at the same time to provide better availability and performance.
- [QuantumLeap](https://quantumleap.rtfd.io/) (version 0.7.5)
  - FIWARE Generic Enabler that supports the storage of FIWARE NGSIv2 data into a time series database, and provides an [API](https://app.swaggerhub.com/apis/smartsdk/ngsi-tsdb/0.7) for accessing the stored data.
  - Normally used to store any changed attribute values according to the subscriptions made to Orion.
  - Uses Crate database to store the data.
  - Uses FIWARE service based access control (provided by the custom Nginx server rules).
  - By default 3 replicas are running at the same time to provide more availability and performance.
- [Grafana](https://grafana.com/) (version 6.5.3)
  - Open source software for time series analytics and visualization.
  - Uses its own user management system that is independent of the access control management provided by Nginx.
  - Can connect directly to the Crate database used by QuantumLeap.
  - Stores user created data (settings, dashboards, etc.) to a PostgreSQL database.
- [Wirecloud](https://wirecloud.rtfd.io/) (version 1.3)
  - FIWARE Generic Enabler that provides a web mashup platform that can be used to develop operational dashboards which are highly customizable by end users.
  - Uses its own user management system that is independent of the access control management provided by Nginx.
  - Stores user created data (settings, dashboards, etc.) to PostgreSQL database.
- [CKAN](https://ckan.org/) (version 2.8) with [FIWARE CKAN extensions](https://fiware-ckan-extensions.rtfd.io/)
  - CKAN is open source data management system that can be used to publish and share data.
  - FIWARE CKAN extensions provide support for publication of datasets matching FIWARE NGSI format.
  - Uses its own user management system that is independent of the access control management provided by Nginx.
  - Stores user created data (settings, dataset information, etc.) to PostgreSQL database.

## Deployment instructions

This section contains instructions on how to setup a new CityIoT FIWARE platform. There are several steps but depending on the deployment options, all of them might not be required .

### System requirements

The platform has been tested on Ubuntu 18.04.3 LTS operating system.

Required software:

- [Bash Shell](https://www.gnu.org/software/bash/) (tested with version 4.4.20)
- [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) (tested with version 19.03.5)
- [Docker Compose](https://docs.docker.com/compose/install/) (tested with version 1.25.1)

At least port 80 needs to be available on the system. Secure connections require also port 443.

### Choosing the deployment options (step 1)

The main deployment options can be found in the file [`main_settings.env`](./main_settings.env). They can be changed manually editing the file with a text editor. The available options:

- `FIWARE_USE_HTTPS`
  - If set to `true`, all network traffic is secured with the HTTPS protocol. Otherwise, unsecure HTTP is used with all network traffic.
- `FIWARE_USE_SUBDOMAINS`
  - If set to `true`, the data usage services Grafana, Wirecloud, and CKAN are all served on their own subdomains, e.g. `https://grafana.<DOMAIN_NAME>`. Otherwise, these services are served on dedicated ports: Grafana on port 3000, Wirecloud on port 8000, and CKAN on port 5000.
- `DOMAIN_NAME`
  - This is the domain name on which the platform will be deployed on. It can be the domain name of the server or an IP address. Even `localhost` or `127.0.0.1` is possible, if the intention is to just test the platform on a local machine. If using an IP address, the HTTPS protocol and the subdomains chosen in the previous options are not available.
- `ORION_VERSION`
  - Setting to choose Orion Context Broker version.
- `ORION_REPLICAS`
  - Setting to choose how many Orion replicas are deployed.
- `FIWARE_INCLUDE_QUANTUMLEAP`
  - Setting to choose whether to include QuantumLeap on the platform. If `true`, QuantumLeap will be included, otherwise not.
- `QL_VERSION`
  - Setting to choose the QuantumLeap version.
- `QL_REPLICAS`
  - Setting to choose how many QuantumLeap replicas are deployed.
- `QL_USE_GEOCODING`
  - Setting to choose whether to use the geocoding feature of QuantumLeap. If `true`, the values for empty location coordinates are determined based on the given street addresses. Otherwise, the feature is not used.
- `FIWARE_INCLUDE_IOTAGENT_UL`
  - Setting to choose whether to include IoT Agent for the Ultralight 2.0 on the platform. If `true`, the IoT Agent will be included, otherwise not.
- `IOTAGENT_UL_VERSION`
  - Setting to choose IoT Agent for the Ultralight 2.0 version.
- `IOTAGENT_UL_REPLICAS`
  - Setting to choose how many IoT Agent for the Ultralight 2.0 replicas are deployed.
- `FIWARE_INCLUDE_GRAFANA`
  - Setting to choose whether to include Grafana on the platform. If `true`, Grafana will be included, otherwise not.
- `FIWARE_INCLUDE_WIRECLOUD`
  - Setting to choose whether to include Wirecloud on the platform. If `true`, Wirecloud will be included, otherwise not.
- `FIWARE_INCLUDE_CKAN`
  - Setting to choose whether to include CKAN on the platform. If `true`, CKAN will be included, otherwise not.

### Choosing the database settings (step 2)

This step involves choosing the main database and the admin user as well as the names of the PostgreSQL databases, usernames for the databases, and the passwords for the users with regards to Grafana, Wirecloud, and CKAN. Thus, this step is not absolutely necessary if none of the three services are included in the platform. This step can also be skipped if the deployer wants to use the default values for the names and passwords (this is NOT recommended practice). Note however, that these usernames and passwords are not the ones used with web applications, those usernames are chosen in the next step (step 3).

The database settings for the main database, Grafana, Wirecloud, and CKAN can be chosen by editing the files `env/secrets/postgres.env`, `env/secrets/grafana.env`, `env/secrets/wirecloud.env`, and `env/secrets/ckan.env`. If these files do not exists yet, they can be created with the default values by running the helper script.

```bash
source create_default_files.sh
```

This script does not change anything about any existing files, and thus it is save to run even after some of the settings have been edited. It is also run during the step 6 to create any missing files if the deployer has skipped any of the previous steps.

The options in `env/secrets/postgres.env`:

- `POSTGRES_DB`
  - The main database name for the PostgreSQL.
- `POSTGRES_USER`
  - The admin username for the PostgreSQL.
- `POSTGRES_PASSWORD`
  - The password for the admin user for the PostgreSQL.

The options in `env/secrets/grafana.env`:

- `GF_DATABASE_NAME`
  - The PostgreSQL database name for Grafana.
- `GF_DATABASE_USER`
  - The PostgreSQL database username for Grafana.
- `GF_DATABASE_PASSWORD`
  - The password for the Grafana user for the PostgreSQL database.

The options in `env/secrets/wirecloud.env`:

- `DB_NAME`
  - The PostgreSQL database name for Wirecloud.
- `DB_USERNAME`
  - The PostgreSQL database username for Wirecloud.
- `DB_PASSWORD`
  - The password for the Wirecloud user for the PostgreSQL database.

The options in `env/secrets/ckan.env`:

- `CKAN_POSTGRES_DB`
  - The PostgreSQL database name for CKAN.
- `CKAN_POSTGRES_USER`
  - The PostgreSQL database username for CKAN.
- `CKAN_POSTGRES_PASSWORD`
  - The password for the CKAN user for the PostgreSQL database.
- `DATASTORE_POSTGRES_DB`
  - The PostgreSQL database name for read-only database for CKAN.
- `DATASTORE_POSTGRES_USER`
  - The PostgreSQL database username for read-only database for CKAN.
- `DATASTORE_POSTGRES_PASSWORD`
  - The password for the read-only CKAN user for corresponding the PostgreSQL database.

### Choosing the admin usernames and passwords (step 3)

This step involves choosing the admin usernames for Grafana, Wirecloud, and CKAN. The actual admin accounts are created for Grafana during step 6 and for Wirecloud and CKAN during step 7. These admin accounts can be used to access the applications and to create any additional user accounts that are needed for the applications.

For Grafana and CKAN also the passwords for the admin users are chosen here. For Wirecloud the password is chosen interactively when the admin account is created in step 7. This step can be skipped if the deployer wants to use the default values for the usernames and passwords (this is definitely NOT recommended in any production environment).

These settings are found in the file `secrets/admins.env`. If this file does not exist yet, it can be created with the default values by running the helper script.

```bash
source create_default_files.sh
```

The options in `secrets/admins.env`:

- `GRAFANA_ADMIN_USER`
  - The username for the admin user for Grafana.
- `GRAFANA_ADMIN_PASSWORD`
  - The password for the admin user for Grafana.
- `WIRECLOUD_ADMIN_USER`
  - The username for the admin user for Wirecloud.
- `CKAN_ADMIN_USER`
  - The username for the admin user for CKAN.
- `CKAN_ADMIN_PASSWORD`
  - The password for the admin user for CKAN.

### Setting the Nginx access control permission (step 4)

The access control for the FIWARE core components, Orion and QuantumLeap as well as the IoT Agent for Ultralight, is handled by the Nginx server. More information on how the access control system works can be found from the [platform document](https://drive.google.com/file/d/1yueGrdArlFmz8ZzchTXWuhbgC9dKUuGN) on chapter 3.3. The permissions for the users of the platform are modified by editing three Nginx configuration files: `secrets/users.conf`, `secrets/services.conf`, and `secrets/proxy_keys.conf`. Any modified access permission will come to effect when the Nginx server is next restarted. On the first install of the platform this happens as the last part of the step 6. Section [Updating Nginx access control permissions](#updating-nginx-access-control-permissions) contains information on how to update the access control rules when the platform is already running. If the configuration files do not exists yet, they can be created with empty permission by running the helper script.

```bash
source create_default_files.sh
```

Users and their tokens are modified by modifying the file `secrets/users.conf`. The template file [`users_template.conf`](secrets/users_template.conf) contains examples on the format of the file. The lines

```bash
    # example users
    'abcdef'         data-provider;
    '123456'         data-viewer;
```

create two users: user called `data-provider`, whose token is `abcdef`, and user `data-viewer`, whose token is `123456`. Note the semicolon at the end of each line. Do not edit the default or intruder users. The tokens are used by providing them as the value of the HTTP header `apikey`. See section [Orion usage examples](#orion-context-broker) for examples of using the tokens.

The permissions for each users are given in the file `secrets/services.conf`. The template file [`services_template.conf`](secrets/services_template.conf) contain examples on the format of the file. The lines

```bash
    # give the data-provider write-access to the service "example"
    data-provider:example         write-access;

    # give the data-provider read-access to all services
    '~^data-provider:(.)*'        read-access;

    # give the data-viewer read access to the service "example"
    data-viewer:example           read-access;
```

gives the user `data-provider` both read and write access to the FIWARE service `example` and read access (GET queries) to all FIWARE services. The user `data-viewer` is only given read access to the FIWARE service `example` and no access to any other FIWARE service. Note the colons between the users and services as well as the semicolons at the end of each line. The second rule gives an example on how to regex with the service names. The access control rules are handled by Nginx line by line in order and the first matching rule is the one that is used.

The file `secrets/proxy_keys.conf` is used to setup the external token modification for the `/notify` endpoint. If no external data sources or this endpoint are in use this last part of step 4 can be skipped.

The external tokens can be used to increase the platform security when using external data sources for the Orion Context Broker by avoiding putting actual CityIoT platform tokens on any external data source. The external tokens are used by the HTTP header `platform-apikey` and they are HTTP request method dependent. The template file [`secrets/proxy_keys_template.conf`](secrets/proxy_keys_template.conf) contains an example on the format of the file. The line

```bash
    'POST:external_token'   'apikey_token';
```

means that, when the `/notify` endpoint is used with a POST request and the value `external_token` for the HTTP header `platform-apikey`, the request is forwarded to the Orion Context Broker (to the endpoint `/v2/op/notify`) with `apikey_token` as the value of the HTTP header `apikey`.

### Getting the SSL certificate (step 5)

This step can be skipped if the setting `FIWARE_USE_HTTPS` in [step 1](#choosing-the-deployment-options-step-1) is set to false.

If the HTTPS is in use, the Nginx server requires three files to be available when it starts:

- `secrets/domain.key`
  - The TLS private key for the domain. Can be generated by the command `openssl genrsa 4096 > secrets/domain.key`
- `secrets/chained.pem`
  - The SSL certificate for the domain.
- `secrets/dhparam.pem`
  - The DH parameter file. Can be generated by the command `openssl dhparam -out secrets/dhparam_.pem 4096`

One way to get a proper SSL certificate for platform domain is to use the free certificates that [Let's Encrypt](https://letsencrypt.org/) provides. Step-by-step instructions for a manual process of getting a Let's Encrypt certificate can be found
from [https://gethttpsforfree.com/](https://gethttpsforfree.com/). Since the free Let's Encrypt certificates are only valid for 90 days, this process must be repeated withing that time to renew the certificate. For a more automated process of getting the certificate, the [getting started](https://letsencrypt.org/getting-started/) documentation can be used.

How to setup the DNS record for the domain name is not covered in this document but it should be noted that if the `FIWARE_USE_SUBDOMAINS` setting is set to true in [step 1](#choosing-the-deployment-options-step-1), then DNS records for the subdomains are also required. Either a wildcard record, `*.<host>`, or individual subdomain records: `grafana.<host>` for Grafana, `wirecloud.<host>` for Wirecloud, and `ckan.<host>` for CKAN. If the [FIWARE access control components](https://github.com/cityiot/fiware-access-control) are used, then `keyrock.<host>` is also required.

Similarly to the DNS records, the SSL certificate also needs to cover the subdomains when they are used. Since one SSL certificate can contain several aliases for the domain name, the main domain and all the subdomains can be covered by a single certificate. Subdomains can be covered by adding a wild card domain name `*.<host>` or by using individual subdomain names as with DNS records.

As the last step before Let's Encrypt assigns the certificate, the user must proof (Let's Encrypt uses ACME challenges) that they can control the content under the domain name they have given. The manual step-by-step instructions contain instruction on how to provide this proof, for example by setting up a temporary HTTP server that fulfills the ACME challenge. This can be used if the FIWARE platform is not yet running and the port 80 can be used freely. For cases when the platform is running, the section [Updating SSL certificate](#updating-ssl-certificate) provides instructions on how to fulfill the given ACME challenge by editing the Nginx configuration files so that there will be no downtime on the platform.

### Installing the platform (step 6)

In this step all the platform components are deployed. While all the other options for the components that were not covered in the previous steps worked well on the CityIoT server, there might be a need to modify some of the settings. If the server does not have large amount of system memory, the CityIoT server had 64GB, the memory settings for the Crate database probably need to be checked. They can be found at the file `env/crate.env`. Other environment options can be found from the other files in the `env/`folder and the version numbers for Grafana, Wirecloud, and CKAN can be found from the file `extra_settings.env`. It is advisable to run the script `update_configurations.sh` before modifying any of these other settings in the `env/` folder. The script modifies for example the host settings based on the `main_settings.env` file. This update script is also run automatically when the platform is deployed but running it before making any extra edits could avoid unnecessary work.

The platform can be deployed with the selected options by running the ready-made script:

```bash
./start_fiware.sh
```

The script has several steps:

- If Docker is not already in swarm mode, switch Docker to swarm mode.
- Set the virtual memory limit (vm.max_map_count) to 262144 if it is something else. This change requires sudo privileges. All other parts of the script can be run without sudo privileges.
- Create a Docker network for the platform if it does not exist yet.
- Run the update_configurations.sh script to modify the environment settings base on the options in main_settings.env.
- Deploy all the docker services one Docker stack at a time. There is a wait time of 30 seconds between each stack deployment to avoid the issue where all services are trying to deploy at the same time and the deployment slows down.
- The Nginx service is deployed last by using a separate script update_nginx.sh. The nginx cannot start properly unless all the other components are already available.

After the start script has finished, the deployment state of each service can be checked using the command `docker service ls`. Below are shown example output for the services related to Orion, MongoDB, QuantumLeap, CrateDB, and Nginx.

```bash
docker service ls

ID                  NAME                                      MODE                REPLICAS            IMAGE
6eenqanud5k3        orion_orion                               replicated          5/5                 fiware/orion:2.3.0
vncsavctf9ib        mongo-rs_controller                       replicated          1/1                 smartsdk/mongo-rs-controller-swarm:latest
lx6muj0xkwrl        mongo-rs_mongodb                          global              1/1                 mongo:3.6.16
o3q85b6rfpli        ql_quantumleap                            replicated          3/3                 smartsdk/quantumleap:0.7.5
z669mqi1ir0f        ql_cratedb                                global              1/1                 crate:3.3.5
n8dlhqmczecd        nginx_nginx                               global              1/1                 nginx:1.15.8
```

For example, the numbers 5/5 for Orion means that all 5 replicated Orion containers indicate that they are ready. And the numbers 1/1 for the Nginx server indicate that the platform should be ready for use. Possible problems can be checked by using the command `docker service logs <service_name>`.

Once all the services are running, the index page can be located at the address: `http://<host>`, where `<host>` is the domain name given in the main_settings.env.

### Adding admin user to Wirecloud and CKAN (step 7)

The admin user accounts for Wirecloud and CKAN are created separately by running the ready-made helper scripts. This step is only necessary on the first start of the platform and only if Wirecloud or CKAN are included on the platform.

The Wirecloud admin user account is created by running the script:

```bash
./create_wirecloud_admin.sh
```

The script uses the username defined in the file `secrets/admins.env` and prompts the user for email address and password. The email address is optional and can be left empty.

The CKAN admin user account is created by running the script:

```bash
./create_ckan_admin.sh
```

The script uses the username and password defined in the file `secrets/admins.env` and prompts the user for email address. The email field is required but it does not need to be a valid email address.

### Uninstalling the platform

All the services for the platform can be stopped by using the helper script:

```bash
./stop_fiware.sh
```

This does not remove any data stored in any of the databases, the data will be still stored in the Docker volumes the platform uses. To remove the data as well as all the Docker images, the command `docker system prune --all --volumes` can be used. Note that this will remove all unused volumes, also those that are not related to the FIWARE platform.

## Platform usage instructions

This section provides examples on how to use APIs of the FIWARE components. The examples assume that the platform has already been deployed and they can be used to test whether the FIWARE components are working properly.

The available platform components are shown as list, when accessing the address `http://<host>`, where `<host>` is the domain name given in the `main_settings.env`. Note, that the index web page always shows all the components even if not all of them were selected during deployment, e.g. Wirecloud links will be shown on the page even if Wirecloud was not installed.

### Orion Context Broker

On the CityIoT FIWARE platform, the FIWARE-NGSI v2 API provided by the Orion Context Broker can be accessed at the address `http://<host>/orion/`, where `<host>` is the domain name given in the `main_settings.env`. Some general API documentation is listed below:

- [The API specification](http://telefonicaid.github.io/fiware-orion/api/v2/stable/)
- [API walkthrough](https://fiware-orion.readthedocs.io/en/latest/user/walkthrough_apiv2/index.html) at the Orion documentation page
- [FIWARE step-by-step](https://fiware-tutorials.readthedocs.io/en/latest/getting-started/index.html) for the Orion Context Broker

For the CityIoT platform also has an access control system that requires the users of the platform to include their token as the value of the HTTP header `apikey` whenever the API is used. In all examples below `<host>` should be replaced by the actual domain name and `<token>` by the token of the user. All examples use the HTTPS address for the platform, and should be replaced with the HTTP addresses if HTTPS is not available.

Without a token, only the version number for Orion can be checked:

```bash
curl --silent --location --request GET "https://<host>/orion/version/"
```

All other queries return status code 401 if the user did not provide a token or the user did not have permission to for the tried operation. Section [Updating Nginx access control permissions](#updating-nginx-access-control-permissions) provides instructions on how to modify the access control rules.

To list the first 10 entities from a selected FIWARE service (`<fiware-service>`) at a selected FIWARE service path (`<fiware-servicepath>`):

```bash
curl --silent --show-error --location \
    --request GET \
    --header "fiware-service: <fiware-service>" \
    --header "fiware-servicepath: <fiware-servicepath>" \
    --header "apikey: <token>" \
    "https://<host>/orion/v2/entities?limit=10" \
| json_pp
```

If you get error message, add `--include` flag to the curl command and remove the "`| json_pp`" part to see more information about the error.

To send a new entity (`<entity_id>`) with a selected entity type (`<entity_type>`)) to Orion:

```bash
curl --silent --show-error --location --include \
    --request POST \
    --header "Content-Type: application/json" \
    --header "fiware-service: <fiware-service>" \
    --header "fiware-servicepath: <fiware-servicepath>" \
    --header "apikey: <token>" \
    "https://<host>/orion/v2/entities" \
    --data @- << EOF
{
    "id": "<entity_id>",
    "type": "<entity_type>",
    "description": {
        "type": "Text",
        "value": "Example data"
    },
    "temperature": {
        "type": "Number",
        "value": 25
    }
}
EOF
```

To update the value of the temperature for the previously created entity:

```bash
curl --silent --show-error --location --include \
    --request PATCH \
    --header "Content-Type: application/json" \
    --header "fiware-service: <fiware-service>" \
    --header "fiware-servicepath: <fiware-servicepath>" \
    --header "apikey: <token>" \
    --data '{"temperature": 28}' \
    "https://<host>/orion/v2/entities/<entity_id>/attrs?options=keyValues"
```

To check that the new entity was correctly created and display all attributes including the automatically created dateModified attribute:

```bash
curl --silent --show-error --location \
    --request GET \
    --header "fiware-service: <fiware-service>" \
    --header "fiware-servicepath: <fiware-servicepath>" \
    --header "apikey: <token>" \
    "https://<host>/orion/v2/entities/<entity_id>\
?type=<entity_type>\
&attrs=*,dateModified\
&metadata=*,dateModified" \
| json_pp
```

Note that the Nginx server provides a cache for the FIWARE platform and it might take up to 60 seconds before any changes on Orion are visible through the API.

### QuantumLeap

On the CityIoT FIWARE platform, the API provided by QuantumLeap can be accessed at the address `http://<host>/quantumleap/`, where `<host>` is the domain name given in the `main_settings.env`. Some general API documentation is listed below:

- [The API specification](https://app.swaggerhub.com/apis/smartsdk/ngsi-tsdb/0.7) on Swagger
- [API walkthrough](https://quantumleap.readthedocs.io/en/latest/user/) at the QuantumLeap documentation page

For the CityIoT platform the access control system works similarly with QuantumLeap as with Orion. In all examples below `<host>` should be replaced by the actual domain name and `<token>` by the token of the user. All examples use the HTTP protocol and by default all calls with HTTP are redirected to HTTPS if it is available.

Without a token, only the version number for QuantumLeap can be checked:

```bash
curl --silent --location --request GET "https://<host>/quantumleap/version/"
```

All other queries return status code 401 if the user did not provide a token or the user did not have permission to for the tried operation. Section [Updating Nginx access control permissions](#updating-nginx-access-control-permissions) provides instructions on how to modify the access control rules.

For QuantumLeap to get the data updates send to Orion, QuantumLeap must be subscribed to the updates. This is done by creating a subscription to Orion. Below is an example for a creating a subscription that causes Orion to send a notification message to QuantumLeap whenever the temperature attribute in any of the entities of type `<entity_type>` are updated. The notification message will containing all the attributes for the entity in question.

```bash
curl --silent --show-error --location --include \
    --request POST \
    --header "Content-Type: application/json" \
    --header "fiware-service: <fiware-service>" \
    --header "fiware-servicepath: <fiware-servicepath>" \
    --header "apikey: <token>" \
    "https://<host>/orion/v2/subscriptions" \
    --data @- << EOF
{
    "description": "Example subscription",
    "subject": {
        "entities": [
            {
                "idPattern": ".*",
                "type": "<entity_type>"
            }
        ],
        "condition": {
            "attrs": [
                "temperature"
            ]
        }
    },
    "notification": {
        "http": {
            "url": "http://quantumleap:8668/v2/notify"
        },
        "attrs": [],
        "metadata": [
            "dateCreated",
            "dateModified",
            "TimeInstant",
            "timestamp"
        ]
    }
}
EOF
```

To fetch the 5 latest entries for all attributes for a selected entity with id `<entity_id>`:

```bash
curl --silent --show-error --location \
    --request GET \
    --header "fiware-service: <fiware-service>" \
    --header "fiware-servicepath: <fiware-servicepath>" \
    --header "apikey: <token>" \
    "https://<host>/quantumleap/v2/entities/<entity_id>?type=<entity_type>&lastN=5" \
| json_pp
```

To fetch the hourly average values for attribute `<attribute_name>` for a selected entity for the 1st June, 2020:

```bash
curl --silent --show-error --location \
    --request GET \
    --header "fiware-service: <fiware-service>" \
    --header "fiware-servicepath: <fiware-servicepath>" \
    --header "apikey: <token>" \
    "https://<host>/quantumleap/v2/entities/<entity_id>\
?type=<entity_type>\
&attrs=<attribute_name>\
&aggrMethod=avg\
&aggrPeriod=hour\
&fromDate=2020-06-01T00:00:00Z\
&toDate=2020-06-01T23:59:59Z" \
| json_pp
```

To fetch the daily maximum values for attribute `<attribute_name>` for all entities of type `<entity_type>` within the month of May 2020:

```bash
curl --silent --show-error --location \
    --request GET \
    --header "fiware-service: <fiware-service>" \
    --header "fiware-servicepath: <fiware-servicepath>" \
    --header "apikey: <token>" \
    "https://<host>/quantumleap/v2/types/<entity_type>/attrs/<attribute_name>\
?aggrMethod=max\
&aggrPeriod=day\
&fromDate=2020-05-01T00:00:00Z\
&toDate=2020-05-31T23:59:59Z" \
| json_pp
```

### IoT Agent for the Ultralight 2.0

### Grafana, Wirecloud, and CKAN

Grafana, Wirecloud, and CKAN are web applications that can be used with FIWARE data. The starting pages and the main documentation pages for the applications are:

- Grafana
  - `http://<host>/grafana/`
  - [QuantumLeap instructions for Grafana](https://quantumleap.readthedocs.io/en/latest/admin/grafana/)
  - [Grafana documentation](https://grafana.com/docs/grafana/latest/getting-started/getting-started/)
- Wirecloud
  - `http://<host>/wirecloud/`
  - [Wirecloud User Guide](https://wirecloud.readthedocs.io/en/stable/user_guide/)
- CKAN
  - `http://<host>/ckan/`
  - [CKAN User Guide](https://docs.ckan.org/en/2.8/user-guide.html)

The admin user accounts for each application are created as part of the deployment process when following the [Deployment instructions](#deployment-instructions). For each application there is an admin interface that can be used to create additional user accounts to the application.

Grafana can be used to connect directly to the database used by QuantumLeap. See appendix A on the [Report on FIWARE Platform](https://drive.google.com/file/d/1yueGrdArlFmz8ZzchTXWuhbgC9dKUuGN) for some notes about the use of Grafana with QuantumLeap.

## Platform management

### Updating deployment options

### Updating Nginx access control permissions

### Updating SSL certificate

### Scaling the components

### Backing and restoring data

Backups for the data that is stored using the CityIoT FIWARE platform can be created using the tool at [tools/backup/](tools/backup). The backups will be stored as 7-Zip compressed files and the tool also contains helper scripts to restore the data from the backups to the FIWARE platform.

### Memory issue with Orion
