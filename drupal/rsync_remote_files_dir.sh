#!/bin/bash

#
# SETUP VARIABLES FROM COMMAND LINE
#
UPDATE=0
AUTOSTART=0
while getopts af:q:u opt; do
    case $opt in
        a) AUTOSTART=1 ;;
        f) DRUPAL_FILES_DIR="$OPTARG" ;;
        q) PROJECT_NAME_QUERY="$OPTARG" ;;
        u) UPDATE=1 ;;
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
      PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR=PantheonSiteSync
    fi
    SCRIPT_ROOT=$(realpath "${BASH_SOURCE[0]}"|grep -o "^.*$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR")
    cd "$SCRIPT_ROOT"
    . ./initialize/initialize.sh -i "minimal" -q "$PROJECT_NAME_QUERY"
fi

if [ -z "$DRUPAL_FILES_DIR" ]; then
    echo '  Could not determine DRUPAL_FILES_DIR, quitting.'
    exit
fi

    . ./drupal/variants/rsync_remote_files_dir-linux.sh

if [ $AUTOSTART -gt 0 ]; then
    INSTALL_TOTAL_START_TIME=$(date +%s)

    drupal_get_files_dir -u "$UPDATE"

    TASK_START_TIME=$INSTALL_TOTAL_START_TIME
    set_task_start_time  -s 'total rsync download time'
    show_tasks_duration
fi
