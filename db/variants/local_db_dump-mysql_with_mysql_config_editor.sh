#!/bin/bash

function local_db_dump() {
    # TABLE EXCLUSION
    local exclude='\(cache\|watch_dog\)'

    # DUMP FILE
    local DATE_FMT='+%Y-%m-%d_%H.%M.%S'

    local dump_file="$SQL_DIR/local_${ENV}_${LOCAL_DB_DB}_"$(date $DATE_FMT).sql

    local dump_base_opts=' --compress --opt'
    local dump_debug_opt=' --extended-insert'
    local dump_data_opts="$dump_base_opts"
    local dump_struct_opts="$dump_base_opts --no-data"

    echo

    #
    # CREATE STRING TO EXCLUDE UNNEEDED TABLES
    #
    set_task_start_time 'getting tables to exclude'

    exclude_tables=$(mysql --login-path=$LOCAL_DB_LOGIN_PATH --execute="SHOW TABLES;" $LOCAL_DB_DB | grep "$exclude" | tr '\n' ',')
    exclude_tables_mysqldump_str=$(echo "$exclude_tables" | gsed "s#\([^,]\+\),# --ignore-table=$LOCAL_DB_DB.\1#g")
    show_tasks_duration

    #
    # GET THE TABLES STRUCTURES
    #
    set_task_start_time 'dumping table structures'
    mysqldump --login-path=$LOCAL_DB_LOGIN_PATH $dump_struct_opts $LOCAL_DB_DB | pv -brt > "$dump_file"
    show_tasks_duration

    #
    # GET THE TABLES DATA
    #
    set_task_start_time 'dumping table data'
    mysqldump --login-path=$LOCAL_DB_LOGIN_PATH $dump_data_opts $exclude_tables_mysqldump_str $LOCAL_DB_DB | pv -brt >> "$dump_file"
    # mysqldump --login-path=$LOCAL_DB_LOGIN_PATH $dump_data_opts $LOCAL_DB_DB | pv -brt >> "$dump_file"
    show_tasks_duration

    chown $USER_USER:$USER_GROUP $dump_file

    tree -sthr $SQL_DIR
}
