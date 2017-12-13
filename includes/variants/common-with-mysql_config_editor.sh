#!/bin/bash

#. ./includes/.bash_profile # Uncomment if you don't have the functions in this file in your .bash_profile file

function function_echo_title() {
    echo
    echo "PROCESSING: ${FUNCNAME[1]}"
}

# It will automatically immediately restart
function kill_mysql_if_dead() {
    local OPTIND
    while getopts l: opt; do
        case $opt in
            l) local login="$OPTARG" ;;
        esac
    done
#   shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
#   OPTIND=1                # Not needed with "local OPTIND"
    if [[ -n "$login" && "$login" != "local" ]]; then
        exit # We only do this for MySQL on our local machine where MySQL is sometimes crashed
    fi
    if [ -n "$(mysql --login-path=local -e "SHOW DATABASES;" 2>&1 | grep 'ERROR')" ]; 
    then 
        pkill -9 mysql
        sleep 2 # Give it some time to restart
    fi
}

function get_REMOTE_DB_PREFIX() {
#   function_echo_title
    local test_table="users_roles"
    local result=($(mysql --login-path="$REMOTE_DB_LOGIN_PATH" "$REMOTE_DB_DB" -e "SHOW TABLES LIKE '%$test_table';"))
    local table="${result[${#result[@]}-1]}"

    if [ "$table" == '\n' ]; then
        table="${result[${#result[@]}-2]}"
    fi
    f1=$(echo "$table" | cut -d'_' -f1)
    if [ "$f1" == 'users' ]; then
        REMOTE_DB_PREFIX=''
    else
        REMOTE_DB_PREFIX="$f1"
    fi
    echo "  Remote DB prefix is '$REMOTE_DB_PREFIX' based on MySQL LIKE pattern '%$test_table'."
    echo
}

function set_LOCAL_DB_PREFIX() {
    local settings_file="$DRUPAL_DEFAULT_DIR/settings.php"
    if [ -z "$LOCAL_DB_PREFIX" ]; then
        if [ ! -f "$settings_file" ]; then
            get_REMOTE_DB_PREFIX
            LOCAL_DB_PREFIX="$REMOTE_DB_PREFIX"
        else
            LOCAL_DB_PREFIX=$(ggrep -P '["'"'"']prefix["'"'"']\s+=>\s+["'"'"'].+["'"'"']' "$settings_file"|ggrep -Pv '\s*[*/#]+'|cut -d'>' -f2|ggrep -oP '\w+')
        fi
    fi
}

function git_commit() {
    local OPTIND
    while getopts F:m: opt; do
        case $opt in
            F) local file="$OPTARG" ;;
            m) local msg="$OPTARG" ;;
        esac
    done
    shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
#   OPTIND=1                # Not needed with "local OPTIND"
    if [ -z "$file" ]; then
        echo "No file supplied for 'git commit'."
        exit
    fi
    if [ -z "$msg" ]; then
        echo "No message supplied for 'git commit'."
        exit
    fi
    if [ -z "$DRUPAL_ROOT" ]; then
        echo "DRUPAL_ROOT not set for 'git commit'."
        exit
    fi
    pushd "$DRUPAL_ROOT" >/dev/null
    local hm="$HOME"
    HOME="/$USERS_BASE_PATH/$USER_USER"
    sudo -u $USER_USER git commit -m "$msg" "$file"
    HOME="$hm"
    popd 2>&1>/dev/null
}

function wake_up_server() {
    local url="$1"
    local keep_alive=$2 # Number in seconds

    local logs="$SCRIPT_ROOT/$LOG_DIR"
    if [ ! -e "$logs" ]; then
        mkdir "$logs"
    fi

    local persist="$logs/${FUNCNAME[0]}.${FUNCNAME[1]}."$(echo "$url" | cut -d'/' -f3)
    if [ -e "$persist" ]; then
        local last_accessed=$(gstat -c %Y "$persist")
        local next_accessed=$(($last_accessed + $keep_alive))
        if [ $(date +%s) -lt $next_accessed ]; then
            echo "  Server should still be awake: $url"
            return
        fi
    fi
    echo $last_accessed > "$persist"

    #
    # MAKE SURE SERVER IS AWAKE
    #
    set_task_start_time "waking up server at: $url"
    if [ -n "$REMOTE_LOCKED_USER_USER" ] && [ -n "$REMOTE_LOCKED_USER_USER" ]; then
        wget --user="$REMOTE_LOCKED_USER_USER" --password="$REMOTE_LOCKED_USER_PSWD" \
             --timeout=5 --tries=3 -qO- "$url" &> /dev/null
    else
        wget --timeout=5 --tries=3 -qO- "$url" &> /dev/null
    fi
    show_tasks_duration
}

function waiting_for_process_to_start() {
    function_echo_title

    local process="$1"
    local wait_to_start_time_max=$2
    WAITED=0
  if [ $(ps aux|grep "$process"|ggrep -Pv '(grep|spawn)'|wc -l) -eq 0 ]; then
        echo "  Waiting for up to '$wait_to_start_time_max' seconds for subprocess '$process' to start."
    while [ $(ps aux|grep "$process"|ggrep -Pv '(grep|spawn)'|wc -l) -eq 0 ]; do
            sleep 1
            ((WAITED++))
            if [ $WAITED -gt $wait_to_start_time_max ]; then
                echo "  Subprocess '$process' not started after '$wait_to_start_time_max' timout."
                return
            fi
        done
    fi
    echo "  Subprocess '$process' started after waiting '$WAITED' seconds."
}

function waiting_for_process_to_end() {
    local process=$1
    local wait_to_start_time_max=$2
    if [ -z "$wait_to_start_time" ]; then
        wait_to_start_time_max=10 # Default to 10 seconds
    fi
    waiting_for_process_to_start "$process" "$wait_to_start_time_max"
    if [ $WAITED -gt $wait_to_start_time_max ]; then
        return
    fi
    function_echo_title
    
    echo "  Waiting for subprocess '$process' to finish."
    WAITED=0
  while [ $(ps aux|grep "$process"|ggrep -Pv '(grep|spawn)'|wc -l) -gt 0 ]; do
        sleep 1
        ((WAITED++))
    done
    echo "  Subprocess '$process' finished."
}

function get_user_and_group() {
    # Even if you sudo to root this will return the actual non-root user which is what we want
  if [ -z "$USER_USER" ]; then
    USER_USER=$(who am i | cut -d' ' -f1)
    if [ "$USER_USER" == 'root' ]; then
        echo 'Could not get non-root user with $(who am i | cut -d'"'" "'"' -f1), quitting.'
        exit
    fi
    if [ -z "$USER_USER" ]; then
        echo 'Could not determine user with $(who am i | cut -d'"'" "'"' -f1), quitting.'
        exit
    fi
  fi
  if [ -z "$USER_GROUP" ]; then
    USER_GROUP=$(groups $USER_USER|cut -d' ' -f3)
    if [ -z "$USER_GROUP" ]; then
      echo 'Could not determine user'"'"'s group with $(who am i | cut -d'"'" "'"' -f3), quitting.'
      exit
    fi
  fi
}
