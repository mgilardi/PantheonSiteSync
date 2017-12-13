#!/bin/bash

PROJECT_ROOT=
function get_project_root_from_project_name_query() {
    local OPTIND
    while getopts n: opt; do
        case $opt in 
            n) PROJECT_NAME_QUERY=$OPTARG ;;
            *) ;;
          esac
    done
#   shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
#   OPTIND=1                # Not needed with "local OPTIND"

    if [ -n "$PROJECT_NAME_QUERY" ]; then
        local dirs=($(find "$PROJECTS_ROOT" -maxdepth 1 -type d -regex "$PROJECTS_ROOT/$PROJECT_NAME_QUERY.*"))
        case ${#dirs[@]} in
            0) echo 'Could not determine project.' ;;
            1) PROJECT_ROOT=${dirs[0]} ;;
            *) 
               echo
               echo 'More than one possible project found, shown below:'
               echo
               printf '  %s\n' "${dirs[@]}"
               echo
               PROJECT_ROOT=''
               ;;
        esac
    fi
    if [ -n "$PROJECT_ROOT" ]; then
        PROJECT_NAME=$(basename "$PROJECT_ROOT")
        PROJECT_ROOT=$(realpath "$PROJECT_ROOT")
    else 
        PROJECT_NAME=''
    fi
}

function set_project_root() {
    local new_project_name
    local OPTIND

    local interaction="full"
    while getopts i: opt; do
        case $opt in 
            i) interaction="$OPTARG" ;;
          esac
    done
#   shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
#   OPTIND=1                # Not needed with "local OPTIND"

    echo
    while [ 1 ]; do
        get_project_root_from_project_name_query

        if [ "$interaction" == 'minimal' ]; then
            break
        fi

        if [ -n "$PROJECT_NAME" ]; then
            local m="The project '$PROJECT_NAME' already exists. Enter=Update, Ctrl+C=Cancel or type a new project name: "
        else
            local m="Enter=Create new project with '$PROJECT_NAME_QUERY' or type a new project name (partial matches allowed): " new_project_name
        fi
        read -p "$m" new_project_name
        if [ -z "$new_project_name" ] && [ -n "$PROJECT_NAME_QUERY" ]; then
            break
        fi
        PROJECT_NAME_QUERY="$new_project_name"
    done
    if [ -z "$PROJECT_ROOT" ]; then
        PROJECT_NAME="$PROJECT_NAME_QUERY"
        PROJECT_ROOT="$PROJECTS_ROOT/$PROJECT_NAME"
    fi
    echo
}
