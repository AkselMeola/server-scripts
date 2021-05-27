#!/bin/bash

###########################################################################
# Remote copy script v1.0
# https://github.com/AkselMeola/server-scripts
#
# Copies files from remote server and stores them in a
# chronological directory structure.
# Expired backups are automatically deleted.
#
# Configuration
# ------------
#
# Files are copied using scp which looks for SSH credentials in ~/.ssh/config
#
# Installation
# ------------
#
# 1. Download script and place it into your executables directory and make it executable
#
#	Example:
#   sudo curl https://raw.githubusercontent.com/AkselMeola/server-scripts/main/remote_backup/remote_backup.sh > /usr/local/bin/remote_backup.sh
#   sudo chmod +x  /usr/local/bin/remote_backup.sh
#
# 2. Modify the configuration variables in the script's "Configuration variables" section
#
# 3. Setup a cron job to run daily.
#
#	Example: Run every day at 4:40 am
#	  40 4 * * *  /usr/local/bin/remote_backup.sh > /var/log/remote_backup.log
#
#
###########################################################################
#
# Configuration variables
#
# How many days to keep backups
KEEP_BACKUPS_DAYS=30

# Directory where backups are stored (without trailing slash)
BACKUP_DIR=~/backups/www.example.com

# Server host configured in your ~/.ssh/config file
SSH_HOST="www.example.com"

# Paths to back up from remote server
# Paths are specified with following scheme: [local_destination]=path/on/server
# Where local_destination is the path relative to BACKUP_DIR
declare -A REMOTE_PATHS=(
  [database]=backups/database/$(date +"%Y-%m-%d")
  [files]=backups/filestest/$(date +"%Y-%m-%d")
)

#
# !!! Do not edit below unless you know what you are doing. !!!
#
# Variables
DEL_TIMESTAMP=$(date -d "-$KEEP_BACKUPS_DAYS days" +"%Y-%m-%d")
CUR_TIMESTAMP=$(date +"%Y-%m-%d")
SCP=$(which scp)
SCP_OPTS="-r"

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
echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: starting backup process:"

for pathInfo in "${!REMOTE_PATHS[@]}"; do
  remotePath=${REMOTE_PATHS[$pathInfo]}
  localPath=$pathInfo

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: backing up $remotePath ..."

  # Prepare destination and copy files
  backupsDestinationPath="$BACKUP_DIR/$localPath"
  mkdir -p $backupsDestinationPath
  $SCP $SCP_OPTS $SSH_HOST:$remotePath/* $backupsDestinationPath

done

# Report on backups directory size
BACKUP_SIZE=`du -sh $BACKUP_DIR | cut -d'/' -f1`
echo "[$(date '+%Y-%m-%d %H:%M:%S')] backup size for $BACKUP_DIR: $BACKUP_SIZE"

# We are done
echo "[$(date '+%Y-%m-%d %H:%M:%S')] backup process finished. All done."

exit 0
