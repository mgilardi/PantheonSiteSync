#!/bin/bash

#
# SETUP VARIABLES FROM COMMAND LINE
#
INTERACTIVENESS="minimal"
PROJECT_NAME_QUERY=""
while getopts i:q: opt; do
  case $opt in
    i) INTERACTIVENESS="$OPTARG" ;;
    q) PROJECT_NAME_QUERY="$OPTARG" ;;
    *) ;;
  esac
done
shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
FILE="$1"
OPTIND=1                # Not needed with "local OPTIND"

filename=$(basename "$FILE")
extension="${filename##*.}"
if [ "$extension" == 'sql' ]; then
  sql="$FILE"
  config=$(dirname $(dirname "$FILE"))/config.sh
else
  config="$FILE"
  sql=$(ls -t $(dirname "$FILE")/sql/remote*.sql | head -1)
fi
if [ -z "$PROJECT_NAME_QUERY" ]; then
  PROJECT_NAME_QUERY=$(basename $(dirname "$config"))
fi

if [ -z "$SCRIPT_ROOT" ]; then
  if [ -z "$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR" ]; then
    PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR=automation
  fi
  SCRIPT_ROOT=$(realpath "${BASH_SOURCE[0]}"|grep -o "^.*$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR")
  cd "$SCRIPT_ROOT"
  . ./initialize/initialize.sh -i "$INTERACTIVENESS" -q "$PROJECT_NAME_QUERY"
fi

INSTALL_TOTAL_START_TIME=$(date +%s)

. ./db/variants/local_db_import-mariadb.sh

TASK_START_TIME=$INSTALL_TOTAL_START_TIME
set_task_start_time  -s 'total rsync download time'
show_tasks_duration
