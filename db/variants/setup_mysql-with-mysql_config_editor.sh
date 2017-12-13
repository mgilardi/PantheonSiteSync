#!/bin/bash

function set_mysql_config_editor() {
    function_echo_title

    local l=''
    local h=''
    local p=''
    local u=''
    local w=''
    while getopts l:h:p:u:w: opt; do
        case $opt in 
            l) l="$OPTARG"  ; local mcekey=$OPTARG ;;
            h) h="$OPTARG" ;;
            p) p="$OPTARG" ;;
            u) u="$OPTARG" ;;
            w) w="$OPTARG" ;;
            *) ;;
          esac
    done
    OPTIND=1

    if [ -z "$(mysql_config_editor print --login-path=$l)" ]; then
        ./db/variants/setup_mysql-with-mysql_config_editor.expect $l $u $p $h $w

        # The mysql_config_editor DB is personal to each user but we may want to
        # to use it both as root and ourselves so once we update the DB we'll copy
        # it to ourselves own directory.
        cp /var/root/.mylogin.cnf /Users/regproctor/
        chown $USER_USER:$USER_GROUP /Users/regproctor/.mylogin.cnf
    else
        echo "  '$mcekey' already in mysql_config_editor DB."
    fi
}

function set_remote_db_in_mysql_config_editor() {
    set_mysql_config_editor -l $REMOTE_DB_LOGIN_PATH -u $REMOTE_DB_USER -p $REMOTE_DB_PORT -h $REMOTE_DB_HOST -w $REMOTE_DB_PSWD
}

function create_db_and_user_privileges() {
    function_echo_title

    local update_pwd=0
    local OPTIND
    while getopts P opt; do # We'll use capitalized options to denote updating
        case $opt in
            P) update_pwd=1 ;;  # Update the password.
        esac
    done
#   shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
#   OPTIND=1                # Not needed with "local OPTIND"

    kill_mysql_if_dead # Automatically restarts
    mysql --login-path=local -e "CREATE DATABASE IF NOT EXISTS $LOCAL_DB_DB;"

    rs=($(mysql --login-path=local -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$LOCAL_DB_USER') AS DB;"))
    if [ ${rs[1]} -eq 0 ]; then
        mysql --login-path=local -e "CREATE USER IF NOT EXISTS '$LOCAL_DB_USER'@'localhost' IDENTIFIED BY '$LOCAL_DB_PSWD';"
        mysql --login-path=local -e "GRANT ALL PRIVILEGES ON $LOCAL_DB_DB.* TO '$LOCAL_DB_USER'@'localhost';"
        mysql --login-path=local -e 'FLUSH PRIVILEGES;'

        echo '  Local DB User created.'
    else
        echo "  Local DB User '$LOCAL_DB_USER' already exists. Updating password."
        if [ $update_pwd -gt 0 ]; then
            mysql --login-path=local -e "SET PASSWORD FOR '$LOCAL_DB_USER'@'localhost' = '$LOCAL_DB_PSWD';"
        fi
    fi
}

function test_mysql_config_editor_user() {
    if [ -z "$(mysql_config_editor print --login-path=$LOCAL_DB_LOGIN_PATH)" ]; then
        echo
        echo '  PLEASE SET YOUR LOCAL DB ROOT USER LOGIN PROFILE WITH:'
        echo
        echo "    mysql_config_editor --login-path=$LOCAL_DB_LOGIN_PATH -u root --password"
        echo
        echo '  and restart this script once you have. Do this as root user as the'
        echo '  file .mylogin.cnf will be copied from the system user to your user' 
        echo "  profile each time it's updated."
        echo
        exit
    fi
}
