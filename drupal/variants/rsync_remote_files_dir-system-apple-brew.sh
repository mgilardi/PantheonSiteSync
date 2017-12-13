#!/bin/bash

RSYNC_PROCESSES=0
function running_rsync_processes() {
  RSYNC_PROCESSES=$(ps aux|grep "sudo rsync"|grep -v 'grep'|wc -l|ggrep -oP '\w+')
}

LAST_RUNNING_RSYNC_PROCESSES=0
function wait_for_running_rsync_processes() {
  local limit=$1
  running_rsync_processes
  while [ $RSYNC_PROCESSES -ge $limit ]; do
    if [ $LAST_RUNNING_RSYNC_PROCESSES -ne $RSYNC_PROCESSES ]; then
      echo "    Running rsync processes: $RSYNC_PROCESSES"
    fi
    LAST_RUNNING_RSYNC_PROCESSES=$RSYNC_PROCESSES
    sleep 1
    running_rsync_processes
  done
}

function drupal_get_files_dir() {
    function_echo_title

    local update=1
    local subdir=''
    local sub='files'
    while getopts "u:s:" opt; do
        case $opt in 
            s) subdir="$OPTARG"; sub=$subdir ;; # This option has not been tested and will be buggy
            u) ;; # update=$OPTARG ;;
        esac
    done
    shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
    OPTIND=1                # Not needed with "local OPTIND"

    wake_up_server "$REMOTE_URL" "$PANTHEON_KEEP_ALIVE"

    if [ -d "$DRUPAL_FILES_DIR" ]; then
        if [ $update -eq 0 ]; then
            echo "  Drupal '$sub' directory already exists, skipping creating it."
            return
        else
            echo "  Drupal '$sub' directory already exists, updating it."
        fi
    else
        echo "  Creating Drupal's files directory."
    fi

    local dir_dst=$(echo "$DRUPAL_DEFAULT_DIR/$subdir" | sed 's:/*$::')
    local dir_src=$(echo "$DRUPAL_FILES_SOURCE/$subdir" | sed 's:/*$::')
    local owner="$WEB_SERVER_USER:$USER_GROUP"
    local batch_file="rsync-tranfer-list"

    if [ -e "$TMP_DIR/$batch_file" ]; then # just in case the script was interrupted.
      rm -f "$TMP_DIR/$batch_file"*
    fi
    if [ $(find $TMP_DIR/ -maxdepth 1 -type f -name "rsync-*" | wc -l|ggrep -oP '\w+') -gt 0 ]; then # just in case the script was interrupted.
      rm -f $TMP_DIR/rsync-*
    fi
    # We sudo here so that if we need to answer "yes" for the root user we do it 
    # here as it will screw us up doing it on the background processes.
    sudo rsync -rluz --delete --progress --ipv4 --dry-run -e 'ssh -p 2222' "${dir_src}" "${dir_dst}" | grep -v '/$' > "$TMP_DIR/$batch_file"
    gsed -i "1d" "$TMP_DIR/$batch_file"
    split -a 3 -l $RSYNC_BATCH_SIZE "$TMP_DIR/$batch_file" "$TMP_DIR/$batch_file-"
    local files=($(gfind $TMP_DIR/ -name "$batch_file-*"))
    local file
    dir_src="$(echo "${dir_src}" | cut -d':' -f1)":
    local count=0
    local bc=${#files[@]}
    for file in "${files[@]}"; do
      wait_for_running_rsync_processes $RSYNC_PROCESSES_MAX
      ((count++))
      local lines=$(cat "$file" | wc -l | tr -d "[:space:]")
      echo "    Starting rsync batch file #: $count of $bc ($lines files)"
      sudo rsync -rluz --delete --ipv4 --log-file="$LOG_DIR/rsync-${count}.log" -og --chown=$owner --files-from="$file" -e 'ssh -p 2222' "${dir_src}" "${dir_dst}" 2>"$LOG_DIR/rsync-${count}.errors" &
      sleep 1
    done
    wait_for_running_rsync_processes 1
    echo "  Finished rsync batch files."
    rm -f "$batch_file"*
}
