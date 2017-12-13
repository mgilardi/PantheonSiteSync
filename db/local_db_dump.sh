#!/bin/bash

#
# SETUP VARIABLES FROM COMMAND LINE
#
while getopts q: opt; do
    case $opt in 
        q) PROJECT_NAME_QUERY="$OPTARG" ;;
        *) ;;
      esac
done
shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
if [ -z "$PROJECT_NAME_QUERY" ] && [ -n "$1" ]; then
    PROJECT_NAME_QUERY="$1"
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

if [ -z "$DRUPAL_FILES_DIR" ]; then
    echo '  Could not determine DRUPAL_FILES_DIR, quitting.'
    exit
fi

INSTALL_TOTAL_START_TIME=$(date +%s)

. ./db/variants/local_db_dump-mariadb.sh
local_db_dump

TASK_START_TIME=$INSTALL_TOTAL_START_TIME
set_task_start_time  -s 'total rsync download time'
show_tasks_duration
