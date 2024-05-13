#!/bin/bash

# Define variables
current_date=$(date +%Y%m%d%H%M%S)
hostname=$(hostname)
backup_root="/tmp/backup-${current_date}"
log_file="/var/log/s3-backup.log"

# Create a temporary backup directory
mkdir -p "${backup_root}/sites"

# Ensure the temporary directory is cleaned up on exit
trap 'rm -rf ${backup_root}' EXIT

# Start logging
{
  echo "Backup started at $(date)"
  
  # Iterate over each user directory in /home
  for user_dir in /home/*; do
    if [ -d "${user_dir}" ]; then
      user=$(basename "${user_dir}")
      
      # Iterate over each site directory
      for site_dir in "${user_dir}"/*.*; do
        if [ -d "${site_dir}/public" ]; then
          site=$(basename "${site_dir}")
          site_backup_dir="${backup_root}/sites/${user}/${site}"
          mkdir -p "${site_backup_dir}"
          
          echo "Processing ${user}/${site}..."
          
          # Check if wp-content exists
          if [ -d "${site_dir}/public/wp-content" ]; then
            zip_target="${site_backup_dir}/${site}.zip"
            echo "Zipping wp-content for ${site}..."
            zip -r "${zip_target}" "${site_dir}/public/wp-content" -x "${site_dir}/public/wp-content/node_modules/*" "${site_dir}/public/wp-content/vendor/*" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
              echo "Error zipping wp-content for ${site}"
            else
              echo "Successfully zipped wp-content for ${site}"
            fi
          else
            zip_target="${site_backup_dir}/${site}.zip"
            echo "Zipping entire public directory for ${site}..."
            zip -r "${zip_target}" "${site_dir}/public" -x "${site_dir}/public/node_modules/*" "${site_dir}/public/vendor/*" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
              echo "Error zipping public directory for ${site}"
            else
              echo "Successfully zipped public directory for ${site}"
            fi
          fi
        fi
      done
    fi
  done
  
  # Define S3 destination directory
  s3_dest="vultr-s3:content-backups/${hostname}/${current_date}/"

  # Copy the backup to S3
  echo "Copying backup to S3..."
  rclone copy "${backup_root}" "${s3_dest}" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error copying backup to S3"
  else
    echo "Successfully copied backup to S3"
  fi

  echo "Backup completed at $(date)"
} | tee -a "${log_file}"