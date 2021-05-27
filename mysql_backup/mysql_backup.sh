#! /bin/bash

########################################################################### 
# Mysql Backup script v1.0
# https://github.com/AkselMeola/server-scripts
#
# Dumps all databases to a dated folder.
# Dumps are gzipped.
# Backups are kept for certain amount of days and removed when expired.
#
# Configuration
# ------------
#
# Mysql client looks for host and credentials in ~/.my.cnf
# For more see MySQL documentation about "option files"
# (Example: https://dev.mysql.com/doc/refman/5.7/en/option-files.html)
#
# NB! Do not pass user credentials on command line! 
# (the command string may appear visible by ps or htop commands)
#
#
# Installation
# ------------
#
# 1. Download script and place it into your executables directory and make it executable 
#
#	Example: 
#	  sudo curl https://raw.githubusercontent.com/AkselMeola/server-scripts/main/mysql_backup/mysql_backup.sh > /usr/local/bin/mysql_backup.sh
#   sudo chmod +x  /usr/local/bin/mysql_backup.sh
#
# 2. Modify the configuration variables in the script's "Configuration variables" section 
#
# 3. Setup a cron job to run daily. 
#
#	Example: Run every day at 4:40 am
#	  40 4 * * *  /usr/local/bin/mysql_backup.sh > /var/log/mysql_backup.log
#
#
########################################################################### 
#
# Configuration variables
#
# How many days to keep backups 
KEEP_BACKUPS_DAYS=30

# Directory where backups are stored (without trailing slash)
BACKUP_DIR=~/backups/database

# Skip schemas from backup
SKIP_SCHEMAS=("mysql" "information_schema" "performance_schema" "sys")

#
# !!! Do not edit below unless you know what you are doing. !!!
#
# Variables
DEL_TIMESTAMP=$(date -d "-$KEEP_BACKUPS_DAYS days" +"%Y-%m-%d")
CUR_TIMESTAMP=$(date +"%Y-%m-%d")
MYSQL_OPTS=""

# Required executables
EXEC_MYSQL=$(which mysql)
EXEC_MYSQLDUMP=$(which mysqldump)

# Create backups dated paths
EXPIRED_BACKUP_DIR="$BACKUP_DIR/$DEL_TIMESTAMP"
BACKUP_DIR="$BACKUP_DIR/$CUR_TIMESTAMP"

# Create dated backups directory
echo "[$(date '+%Y-%m-%d %H:%M:%S')] creating directory $BACKUP_DIR"
mkdir -p $BACKUP_DIR
if [[ $? != 0 ]]; then
  echo "Unable to create backups directory at $BACKUP_DIR" 
  exit 1
fi

# Remove expired backup directory
echo "[$(date '+%Y-%m-%d %H:%M:%S')] removing expired backups directory $EXPIRED_BACKUP_DIR"
rm -rf $EXPIRED_BACKUP_DIR


echo "[$(date '+%Y-%m-%d %H:%M:%S')] querying for schemas to back up ..."
databases=$($EXEC_MYSQL $MYSQL_OPTS -e "SELECT schema_name FROM information_schema.schemata ORDER BY schema_name ASC;" | grep -Ev "(schema_name)")

#Loop schemas and dump to file
echo "[$(date '+%Y-%m-%d %H:%M:%S')] starting backup process:"
for db in $databases; do
   if [[ " ${SKIP_SCHEMAS[*]} " == *" $db "* ]]; then
     echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skipping db: $db"
     continue
   fi

   echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backing up: $db"

   $EXEC_MYSQLDUMP $MYSQL_OPTS --force --no-create-db --opt $db | gzip > "$BACKUP_DIR/$db.gz"
done

# Report on backups directory size
BACKUP_SIZE=`du -sh $BACKUP_DIR | cut -d'/' -f1`
echo "[$(date '+%Y-%m-%d %H:%M:%S')] backup size for $BACKUP_DIR: $BACKUP_SIZE"

# We are done
echo "[$(date '+%Y-%m-%d %H:%M:%S')] backup process finished. All done."

exit 0
