#!/bin/bash

#
# SETUP VARIABLES FROM COMMAND LINE
#
AUTOSTART=0
while getopts aq: opt; do
    case $opt in
        a) AUTOSTART=1 ;;
        q) PROJECT_NAME_QUERY="$OPTARG" ;;
    esac
done
shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
if [ -z "$PROJECT_NAME_QUERY" ] && [ -n "$1" ]; then
    PROJECT_NAME_QUERY="$1"
fi
if [ $AUTOSTART -eq 0 ] && [ -n "$2" ]; then
    AUTOSTART=$2
fi
OPTIND=1                # Not needed with "local OPTIND"
#
# END - SETUP VARIABLES FROM COMMAND LINE
#

if [ -z "$SCRIPT_ROOT" ]; then
    if [ -z "$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR" ]; then
      PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR=automation
    fi
    SCRIPT_ROOT=$(realpath "${BASH_SOURCE[0]}"|grep -o "^.*$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR")
    cd "$SCRIPT_ROOT"
    . ./initialize/initialize.sh -i "minimal" -q "$PROJECT_NAME_QUERY"
fi

. ./db/variants/download_remote_db-mariadb.sh

if [ $AUTOSTART -gt 0 ]; then
    TOTAL_DB_START_TIME=$(date +%s)

    download_remote_db

    newest_remote_sql_file=$(ls -t "$SQL_DIR/remote"*.sql | head -1)
    if [ -z "$newest_remote_sql_file" ]; then
      echo '  Local DB file to import not found.'
    else
      . ./db/local_db_import.sh "$newest_remote_sql_file"
      if [ -z "$(type -t 'set_local_user_one_pass')" ]; then
          . ./drupal/drupal_setup.sh
      fi
      set_local_user_one_pass
    fi

    TASK_START_TIME=$TOTAL_DB_START_TIME
    set_task_start_time  -s 'total DB download time'
    show_tasks_duration
fi
