#!/bin/bash

#
# FUNCTIONS
#
function set_task_start_time() {
    local OPTIND o
    local skip=0
        while getopts "s" o; do
        case "${o}" in
            s) skip=1;; # Skip setting start time
        esac
    done
    shift $((OPTIND-1))

    if [ $skip -eq 0 ]; then
        TASK_START_TIME=$(gdate +%s)
    fi
    echo '  Started: '$(gdate -d@${TASK_START_TIME} +%H:%M:%S) "- $1"
}

function show_tasks_duration() {
    local end_time=$(gdate +%s)
    local duration=$(( $end_time - $TASK_START_TIME ))
    echo '    Ended: '$(gdate -d@${end_time} +%H:%M:%S)
    echo ' Duration: '$(gdate -d@${duration} -u +%H:%M:%S)
    echo
}
export -f set_task_start_time
export -f show_tasks_duration
#
# END - FUNCTIONS
#
