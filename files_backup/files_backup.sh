#! /bin/bash

###########################################################################
# Files Backup script v1.0
# https://github.com/AkselMeola/server-scripts
#
# Copies configured directories to array dated folder.
# Backups are kept for certain amount of days and removed when expired.
#
# Installation
# ------------
#
# 1. Download script and place it into your executables directory and make it executable
#
#	Example:
#	  sudo curl https://raw.githubusercontent.com/AkselMeola/server-scripts/main/files_backup/files_backup.sh > /usr/local/bin/files_backup.sh
#   sudo chmod +x  /usr/local/bin/files_backup.sh
#
# 2. Modify the configuration variables in the script's "Configuration variables" section
#
# 3. Setup a cron job to run daily.
#
#	Example: Run every day at 4:40 am
#	  40 4 * * *  /usr/local/bin/files_backup.sh > /var/log/files_backup.log
#
###########################################################################
#
# Configuration variables
#
# How many days to keep backups
KEEP_BACKUPS_DAYS=30

# Directory where backups are stored (without trailing slash)
BACKUP_DIR=~/backups/files

# Paths to back up
BACKUP_PATHS=(
  ~/domains/www.example.com/htdocs
  ~/domains/www.example.com/testing
)

# Paths to skip in those paths (full paths)
SKIP_PATHS=(
  ~/domains/www.example.com/public/tmp
)

# Backed up files are prefixed with this string (optional, without leading slash)
# Example: DESTINATION_PREFIX="domains/"
# Resulting paths would then be:
#    ~/backups/files/YYYY-MM-DD/domains/htdocs
#    ~/backups/files/YYYY-MM-DD/domains/testing
DESTINATION_PREFIX=""

#
# !!! Do not edit below unless you know what you are doing. !!!
#
# Variables
DEL_TIMESTAMP=$(date -d "-$KEEP_BACKUPS_DAYS days" +"%Y-%m-%d")
CUR_TIMESTAMP=$(date +"%Y-%m-%d")

# Create backups dated paths
EXPIRED_BACKUP_DIR="$BACKUP_DIR/$DEL_TIMESTAMP"
BACKUP_DIR="$BACKUP_DIR/$CUR_TIMESTAMP"

# Remove expired backup directory
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: removing expired backups directory $EXPIRED_BACKUP_DIR"
rm -rf $EXPIRED_BACKUP_DIR

# Create dated backups directory
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: creating directory $BACKUP_DIR"
mkdir -p $BACKUP_DIR
if [[ $? != 0 ]]; then
  echo "ERROR: Unable to create backups directory at $BACKUP_DIR"
  exit 1
fi

# Loop backup paths
for backupPath in ${BACKUP_PATHS[@]}; do
  # Expand wildcard paths
  for realPath in $(realpath $backupPath); do
    if [[ " ${SKIP_PATHS[*]} " == *" $realPath "* ]]; then
       echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: skipping path: $realPath"
       continue
    fi

    backupsBasename=$(basename $(dirname "$realPath"))
    backupsDestinationPath="$BACKUP_DIR/${DESTINATION_PREFIX}${backupsBasename}"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: backing up $realPath"

    # Prepare destination and copy files
    mkdir -p $backupsDestinationPath
    cp -rf $realPath $backupsDestinationPath/

  done
done

# Report on backups directory size
BACKUP_SIZE=`du -sh $BACKUP_DIR | cut -d'/' -f1`
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: backup size for $BACKUP_DIR: $BACKUP_SIZE"

# We are done
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: backup process finished. All done."

exit 0
