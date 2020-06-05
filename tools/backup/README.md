# Scripts for creating backups of the FIWARE data and for restoring the data from the backups

This folder contains scripts to backup and restore the data that is stored using the CityIoT FIWARE platform. The backups are stored as 7-Zip compressed files in the selected folder, `<backup_folder>`. Some of the scripts require also the `<platform_folder>` as a parameter, which should be the folder containing the main FIWARE platform settings file, `main_settings.env`.

## Creating data backup

- For creating a full backup of the FIWARE data contained in Mongo, Crate and PostgreSQL databases.

    ```bash
    source full_backup.sh <backup_folder> <platform_folder>
    ```

- For creating a partial backup of the FIWARE data that contains the full data from Mongo (used by Orion) and all data from Crate (used by QuantumLeap) starting from the given date, i.e. data for which the timestamp is `<start_date>T00:00:00Z` or later. Also the full data from PostgreSQL databases (used by Grafana, Wirecloud and CKAN) is included in the backup. The start date is given in ISO 8601 format, e.g. 2020-06-01 for the 1st of June 2020.

    ```bash
    source full_backup.sh <backup_folder> <platform_folder> <start_date>
    ```

- For creating a partial backup that contains all the data since the previous backup. If the last backup was done on the 13th of January 2020, then this would be the same as using `source full_backup.sh <backup_folder> <platform_folder> 2020-01-13`.

    ```bash
    source full_backup.sh <backup_folder> --update
    ```

The backed up data will be contained as 7-zip compressed files at folder `<backup_folder>` as files

- `backup_ql_data.<current_date>.7z`
- `backup_orion_data.<current_date>.7z`
- `backup_postgres_data.<current_date>.7z`

Note that running the backup more than once in the same day will overwrite files created in the previous backup.

Also, when the backup script is run, the configuration files needed for the FIWARE components are backup up. These can be found in the same folder as file

- `backup_config_data.<current_date>.7z`

## Restoring data

- To restore data to the Mongo database used by Orion (uses the most recent Mongo backup in the given directory):

    ```bash
    sudo ./restore_mongo_data.sh <backup_folder>
    ```

- To copy data from a Crate backup to the database used by QuantumLeap (goes through all QL-backup files in the given directory):

    ```bash
    sudo ./restore_crate_data.sh <backup_folder> [--update_schemas]
    ```

    If the option `--update-schemas` is given, the table schemas are also updated in the database. Otherwise, only the data is copied.

- To restore data to the PostgreSQL databases used by Grafana, Wirecloud and CKAN (uses the most recent PostgreSQL backup in the given directory):

    ```bash
    ./restore_postgres_data.sh <backup_folder> <platform_folder>
    ```
