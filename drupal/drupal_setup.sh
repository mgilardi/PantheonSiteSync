#!/bin/bash

#
# Do getopts before calling any in-line scripts in case they look for positional parameters
#
while getopts f: opt; do
  case $opt in
    f) func="$OPTARG" ;;
  esac
done
shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
if [ -z "$PROJECT_NAME_QUERY" ] && [ -n "$1" ]; then
  PROJECT_NAME_QUERY="$1"
fi
OPTIND=1                # Not needed with "local OPTIND"

if [ -z "$SCRIPT_ROOT" ]; then
  if [ -z "$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR" ]; then
    PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR=automation
  fi
  SCRIPT_ROOT=$(realpath "${BASH_SOURCE[0]}"|grep -o "^.*$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR")
  cd "$SCRIPT_ROOT"
  . ./initialize/initialize.sh -i "minimal" -q "$PROJECT_NAME_QUERY"
fi

. ./drupal/variants/drupal_setup-with-mariadb.sh

if [ -n "$func" ]; then
  $func
fi
