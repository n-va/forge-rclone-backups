#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Create a temporary directory for the backup process
temp_dir=$(mktemp -d)

# Ensure the temporary directory is deleted on exit
trap "rm -rf ${temp_dir}" EXIT

# Create base directories for backups in the temporary directory
mkdir -p "${temp_dir}/backup/sites"

# Log file
log_file="/var/log/s3-backup.log"

# Redirect stdout and stderr to the log file
exec > >(tee -i ${log_file})
exec 2>&1

echo "Backup started at $(date)"

# Get the server hostname
hostname=$(hostname)

# Get the current date and time in yyyyMMddHHmmss format
current_datetime=$(date +%Y%m%d%H%M%S)

# Iterate over each user's home directory
for user_dir in /home/*; do
    if [ -d "${user_dir}" ]; then
        echo "Processing user directory: ${user_dir}"

        # Iterate over each site directory in the user's home directory
        for site_dir in "${user_dir}"/*; do
            if [ -d "${site_dir}/public" ]; then
                echo "Found site directory: ${site_dir}/public"

                # Get the site name from the directory name
                site_name=$(basename "${site_dir}")

                # Define the backup file name
                backup_file="${temp_dir}/backup/sites/${site_name}.zip"

                # Check if the wp-content directory exists inside public
                if [ -d "${site_dir}/public/wp-content" ]; then
                    echo "Found wp-content directory in: ${site_dir}/public"

                    # Compress the wp-content directory into a zip file, excluding node_modules and vendor directories
                    zip -rq "${backup_file}" "${site_dir}/public/wp-content" -x '*node_modules*' -x '*vendor*'
                else
                    echo "No wp-content directory found in ${site_dir}/public, zipping entire public directory"

                    # Compress the entire public directory into a zip file, excluding node_modules and vendor directories
                    zip -rq "${backup_file}" "${site_dir}/public" -x '*node_modules*' -x '*vendor*'
                fi

                # Define the S3 bucket path
                s3_path="vultr-s3:content-backups/${hostname}/${current_datetime}/"

                # Push the backup to Vultr Object Storage
                rclone copy "${backup_file}" "${s3_path}"

                # Delete the local backup file
                rm "${backup_file}"
            else
                echo "No 'public' directory found in ${site_dir}"
            fi
        done
    else
        echo "No user directory found: ${user_dir}"
    fi
done

echo "Backup completed at $(date)"
