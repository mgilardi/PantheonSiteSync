#!/bin/bash

function dump_db() {
    local OPTIND
    local db
    local name
    local pass
    local host
    local keepAlive
    local port
    local url
    while getopts d:n:p:H:K:P:U: opt; do
        case $opt in
          d)   db="$OPTARG" ;;
          n) name="$OPTARG" ;;
          p) pass="$OPTARG" ;;
          H) host="$OPTARG" ;;
          K) keepAlive="$OPTARG" ;;
          P) port="$OPTARG" ;;
          U)  url="$OPTARG" ;;
          *) ;;
        esac
    done
#   shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
#   OPTIND=1                # Not needed with "local OPTIND"

    # TABLE EXCLUSION
    local exclude='\(cache\|watch_dog\)'

    # DUMP FILE
    local DATE_FMT='+%Y-%m-%d_%H.%M.%S'

    local dump_file="$SQL_DIR/remote_${ENV}_${LOCAL_DB_DB}_"$(date $DATE_FMT).sql

    local dump_base_opts=' --compress --opt'
    local dump_debug_opt=' --extended-insert'
    local dump_data_opts="$dump_base_opts"
    local dump_struct_opts="$dump_base_opts --no-data"

    echo

    #
    # MAKE SURE SERVER IS AWAKE
    #
    wake_up_server "$REMOTE_URL" "$PANTHEON_KEEP_ALIVE"

    #
    # CREATE STRING TO EXCLUDE UNNEEDED TABLES - this can reduce download time immensely
    #
    set_task_start_time 'getting tables to exclude'

    exclude_tables=$(mysql --login-path=$REMOTE_DB_LOGIN_PATH --execute="SHOW TABLES;" $REMOTE_DB_DB | grep "$exclude" | tr '\n' ',')
    exclude_tables_mysqldump_str=$(echo "$exclude_tables" | gsed "s#\([^,]\+\),# --ignore-table=$REMOTE_DB_DB.\1#g")
    show_tasks_duration

    #
    # GET THE TABLES STRUCTURES
    #
    set_task_start_time 'dumping table structures'
    mysqldump --login-path=$REMOTE_DB_LOGIN_PATH $dump_struct_opts $REMOTE_DB_DB | pv -brt > "$dump_file"
    show_tasks_duration

    #
    # GET THE TABLES DATA
    #
    set_task_start_time 'dumping table data'
    mysqldump --login-path=$REMOTE_DB_LOGIN_PATH $dump_data_opts $exclude_tables_mysqldump_str $REMOTE_DB_DB | pv -brt >> "$dump_file"
    # mysqldump --login-path=$REMOTE_DB_LOGIN_PATH $dump_data_opts $REMOTE_DB_DB | pv -brt >> "$dump_file"
    show_tasks_duration

    chown $USER_USER:$USER_GROUP $dump_file

    tree -sthr $SQL_DIR
}

function download_remote_db() {
    # TABLE EXCLUSION
    local exclude='\(cache\|watch_dog\)'

    # DUMP FILE
    local DATE_FMT='+%Y-%m-%d_%H.%M.%S'

    local dump_file="$SQL_DIR/remote_${ENV}_${LOCAL_DB_DB}_"$(date $DATE_FMT).sql

    local dump_base_opts=' --compress'
    local dump_debug_opt=' --extended-insert'
    local dump_data_opts="$dump_base_opts --add-drop-table --no-create-info"
    local dump_struct_opts="$dump_base_opts --no-data"

    echo

    #
    # MAKE SURE SERVER IS AWAKE
    #
    wake_up_server "$REMOTE_URL" "$PANTHEON_KEEP_ALIVE"

    #
    # CREATE STRING TO EXCLUDE UNNEEDED TABLES - this can reduce download time immensely
    #
    set_task_start_time 'getting tables to exclude'

    exclude_tables=$(mysql --login-path=$REMOTE_DB_LOGIN_PATH --execute="SHOW TABLES;" $REMOTE_DB_DB | grep "$exclude" | tr '\n' ',')
    exclude_tables_mysqldump_str=$(echo "$exclude_tables" | gsed "s#\([^,]\+\),# --ignore-table=$REMOTE_DB_DB.\1#g")
    show_tasks_duration

    #
    # GET THE TABLES STRUCTURES
    #
    set_task_start_time 'dumping table structures'
    mysqldump --login-path=$REMOTE_DB_LOGIN_PATH $dump_struct_opts $REMOTE_DB_DB | pv -brt > "$dump_file"
    show_tasks_duration

    #
    # GET THE TABLES DATA
    #
    set_task_start_time 'dumping table data'
    mysqldump --login-path=$REMOTE_DB_LOGIN_PATH $dump_data_opts $exclude_tables_mysqldump_str $REMOTE_DB_DB | pv -brt >> "$dump_file"
    # mysqldump --login-path=$REMOTE_DB_LOGIN_PATH $dump_data_opts $REMOTE_DB_DB | pv -brt >> "$dump_file"
    show_tasks_duration

    chown $USER_USER:$USER_GROUP $dump_file

    tree -sthr $SQL_DIR
}
