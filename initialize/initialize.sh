#!/bin/bash

INITIALIZE_START_TIME=$(date +%s)

if [ -z "$(type -t 'set_task_start_time')" ]; then
    # Consider putting these functions in your .bash_profile file instead of 
    # loading them dynamically
    . ./includes/.bash_profile.sh
fi

. ./includes/common.sh
get_user_and_group
. ./config/system.sh
. ./config/user.sh
. ./config/pantheon.sh

function init_project_name() {
    . ./initialize/project.sh
    set_project_root -i "$INTERACTION"
}

function init_config_file_and_vars() {
    CONFIG_FILE="$PROJECT_ROOT/config.sh"

    . ./initialize/config_file.sh
    if [ ! -e "$PROJECT_ROOT" ]; then
        local answer=
        read -p "Are you sure you wish to create a new project [y/n]? " answer
        if [ "$answer" != 'y' ]; then
            exit
        fi
        setup_config_file
    fi
    . "$CONFIG_FILE"
    process_config_file_variables
}

function init_sql_dir() {
    SQL_DIR="$PROJECT_ROOT/sql"
    if [ ! -e "$SQL_DIR" ]; then
        sudo -u $USER_USER mkdir "$SQL_DIR"
    fi
}

INTERACTION="full"
while getopts i:q: opt; do
    case $opt in 
        i) INTERACTION="$OPTARG" ;;
        q) PROJECT_NAME_QUERY="$OPTARG" ;;
    esac
done
shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
if [ -z "$PROJECT_NAME_QUERY" ] && [ -n "$1" ] ; then
    PROJECT_NAME_QUERY="$1"
fi
OPTIND=1                # Not needed with "local OPTIND"

init_project_name
init_config_file_and_vars
init_sql_dir

TASK_START_TIME=$INITIALIZE_START_TIME
set_task_start_time  -s 'total initializing time'
show_tasks_duration
