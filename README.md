# Backup Script for User Site Directories

This repository contains a script for backing up site files from each user's home directory on a server. The script is designed to handle WordPress installations but can be used for other types of sites as well. The backup files are stored in a Vultr Object Storage bucket, organized by the server's hostname and the current date and time.

## Features

- Backs up site files from each user's home directory.
- Checks each site directory for a `public` folder.
- If `wp-content` is found within `public`, it backs up only this folder, excluding `node_modules` and `vendor`.
- If `wp-content` is not found, it backs up the entire `public` directory, also excluding `node_modules` and `vendor`.
- Zipped backup files are named after the site and uploaded to Vultr Object Storage in a directory named by the server's hostname and the current date-time.
- Implements logging to `/var/log/s3-backup.log`.
- Ensures temporary directories are cleaned up after the script runs.
- Uses `set -e` to ensure the script exits on any command failure.

## Requirements

- [`rclone`](https://rclone.org/downloads/) configured to use Vultr Object Storage.
- Proper permissions to access user directories and run the script.
- Sufficient space for temporary storage during the backup process.

## Installation

1. Clone this repository to your server.
2. Ensure the script is executable:
    ```bash
    chmod +x s3-backup.sh
    ```
3. Install `rclone` by following the instructions on the [rclone downloads page](https://rclone.org/downloads/).
4. Configure `rclone` to use your Vultr Object Storage. You can find the configuration instructions [here](https://rclone.org/s3/).

## Usage

Run the script with superuser privileges to ensure it has the necessary permissions to access all user directories and perform the backups:

```bash
sudo ./s3-backup.sh
```

## Script Details

### Backup Logic

1. The script iterates over each user's home directory (`/home/*`).
2. For each user directory, it looks for site directories containing a `public` folder.
3. If a `public/wp-content` directory is found, it backs up only this folder, excluding `node_modules` and `vendor`.
4. If no `wp-content` directory is found, it backs up the entire `public` folder, also excluding `node_modules` and `vendor`.
5. Backup files are compressed into zip files and named after the site.
6. The zip files are uploaded to a Vultr Object Storage bucket, organized by the server's hostname and the current date-time.
7. Temporary files are cleaned up after the script completes.

### Logging

The script logs its activities to `/var/log/s3-backup.log`, including start and completion times, and any errors encountered during the process.

### Error Handling

The script uses `set -e` to ensure it exits immediately if any command fails, preventing incomplete or corrupted backups.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please submit pull requests or open issues to suggest improvements or report bugs.

## Contact

For any questions or support, please open an issue in this repository.
