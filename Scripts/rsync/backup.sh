#!/bin/bash

function begin(){
        echo "-------------------------------------"
        echo "Beginning Script $0 - $(date '+%Y%m%d-%H%M%S')"
        echo "-------------------------------------"
        echo "Usage"
        echo "-------------------------------------"
        echo -n "\
                ${0/\.\//} ${1:-\"'{1}' - exlude_file\"} \
                ${2:-\"'{2}' - source[]\"} \
                ${3:-\"'{3}' - destination\"} \
                (working on getting remote host from destination)" | tr  -d $'\t'
        echo "-------------------------------------"
        umask 133 # 644 file permissions, subtract from 777
}

function variables_to_change(){
        BACKUP_DIR='/backup/docker'
        LOG_DIR='${BACKUP_DIR}/logs'
        DOCKER_CONTAINER_DATA_PATH='/storage/containers/'
        SCRIPTS_DIR='~/Scripts'
        }

function variables_not_change(){
        read -r WEEK DOW YEAR_NUM MONTH DAY DOM TIME <<< "$(date +'%W %u %Y %B %a %-d %T')"
        [ -z $1 ] && exclude="${SCRIPTS_DIR}/rsync/.rsync-filter-daily" || exclude="$(readlink -f ${1})"
        user="$(id -un)"
        group="$(id -gn)"
        MONTH_NAME=${MONTH,,}
        DAY_NAME=${DAY,,}       #same as - (date +%a    | tr '[:upper:]' '[:lower:]')
        WEEK_NUM_OF_MONTH=$((($DOM-1)/7+1))
        #       Destination Directories
        MONTHLY_BACKUP_DIR="$BACKUP_DIR/$YEAR_NUM/$MONTH_NAME"  # Monthly backup directory
        WEEKLY_BACKUP_DIR="$MONTHLY_BACKUP_DIR/$WEEK_NUM_OF_MONTH"  # Weekly backup directory
        DAILY_BACKUP_DIR="$WEEKLY_BACKUP_DIR/$DAY_NAME"
        WORKING_DIR=($DOCKER_CONTAINER_DATA_PATH $SCRIPTS_DIR)
        RSYNC_CMD="eval rsync -Pzmav --delete --prune-empty-dirs --exclude-from=${exclude}"
        }

function create_directory_file(){
        [ -d $DAILY_BACKUP_DIR ] || mkdir -p $DAILY_BACKUP_DIR
        }

function backup(){
        if [ $DOM -eq 01 ]; then
                echo "-----------------------------------"
                echo "Performing monthly backup at $MONTHLY_BACKUP_DIR"
                echo "-----------------------------------"
                        $RSYNC_CMD "${WORKING_DIR[@]}" $MONTHLY_BACKUP_DIR
                echo "Pruning previous months' backups..."
                find $MONTHLY_BACKUP_DIR/ -maxdepth 1 -type d ! -name $MONTH_NAME -exec rm -rf {} +
                echo "-----------------------------------"
                echo "Monthly backup completed."
                echo "-----------------------------------"
        elif [ $DOW -eq 7 ]; then
                echo "-----------------------------------"
                echo "Performing weekly backup at $WEEKLY_BACKUP_DIR"
                echo "-----------------------------------"
                        $RSYNC_CMD "${WORKING_DIR[@]}" $WEEKLY_BACKUP_DIR
                echo "Pruning additional weekly backups..."
                find $WEEKLY_BACKUP_DIR/ -maxdepth 1 -type d -mtime +14 -exec rm -rf {} +
                echo "-----------------------------------"
                echo "Weekly backup completed."
                echo "-----------------------------------"
        else
                echo "-----------------------------------"
                echo "Performing daily backup at $DAILY_BACKUP_DIR"
                echo "-----------------------------------"
                        $RSYNC_CMD "${WORKING_DIR[@]}" $DAILY_BACKUP_DIR
                echo "-----------------------------------"
                echo "Daily backup completed."
                echo "-----------------------------------"
        fi
        echo "Script completed at $(date '+%Y%m%d-%H%M%S')"
}

function main(){
        begin
        variables_to_change
        variables_not_change
        create_directory_file
        backup >| "$LOG_DIR/$(date '+%Y%m%d%H%M%S')"
        }

main
