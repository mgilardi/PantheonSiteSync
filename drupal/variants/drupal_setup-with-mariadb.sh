#!/bin/bash

function drupal_get_git_files() {
  function_echo_title

  if [ -e "$DRUPAL_ROOT" ]; then
    echo "  DRUPAL_ROOT found at: $DRUPAL_ROOT, no need to 'git clone'."
    return
  fi

  if [ -z "$DRUPAL_GIT_CLONE" ]; then
    echo "  Cannot create DRUPAL_ROOT because  DRUPAL_GIT_CLONE is empty."
    echo "  Please set it in: $CONFIG_FILE"
    exit
  fi

  pushd "$PROJECT_ROOT" >/dev/null
  local hm=$HOME
  HOME="/$USERS_BASE_PATH/$USER_USER"
  sudo -u $USER_USER $DRUPAL_GIT_CLONE 2>&1 | sed -e 's/^/  /g'
  HOME=$hm
  popd 2>&1>/dev/null

  if [ -e "$DRUPAL_ROOT" ]; then
    echo "  DRUPAL_ROOT and it's files have been created."
    return
  fi
  echo '  DRUPAL_ROOT could not be created, aborting.'
  exit
}

function append_file_and_git_commit() {
  local OPTIND
  while getopts d:k:m:s: opt; do
    case $opt in
      d) local dst="$OPTARG"; local dst_fn=$(basename "$dst") ;;
      k) local key="$OPTARG" ;;
      m) local msg="$OPTARG" ;;
      s) local src="$OPTARG" ;;
    esac
  done
  shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
# OPTIND=1                # Not needed with "local OPTIND"

  local key_esc=$(echo $key|sed -e 's/\./\\./g')
  if grep --quiet "$key_esc" "$dst"; then
    echo "  $dst_fn already includes '$key'"
  else
    cat "$src" >> "$dst"
    echo "  $msg"
    git_commit -m "$msg." -F "$dst"
  fi
}

#
# settings.php
#
function set_settings_php_file() {
  function_echo_title

  #
  # TEMPLATE: settings.php-settings.local.php.template
  #
  local settings_php_file="$(dirname $DRUPAL_FILES_DIR)/settings.php"

  local key='settings.local.php'
  append_file_and_git_commit \
      -d "$settings_php_file" \
      -k "$key" \
      -m "Adding code to 'settings.php' to include '$key'." \
      -s "$(dirname $(dirname ${BASH_SOURCE[0]}))/templates/settings.php-settings.local.php.template"

  #
  # TEMPLATE: settings.php-settings.local.php.template
  #
  key='is_live_website'
# append_file_and_git_commit \
#   -d "$settings_php_file" \
#   -k "$key" \
#   -m "Adding ability to initialize performance settings on live environments." \
#   -s "$(dirname $(dirname ${BASH_SOURCE[0]}))/templates/settings.php-is_live_website.template"

}
 
#
# settings.local.php
#
function set_settings_local_php_file() {
  function_echo_title

  local slp="$DRUPAL_DEFAULT_DIR/settings.local.php"

  if [ -e "$slp" ]; then
    echo '  "settings.local.php" already exists, skipping creation.'
    return
  fi
  set_LOCAL_DB_PREFIX
  local template_path=$(dirname $(dirname ${BASH_SOURCE[0]}))/templates/settings.local.php.template
  if [ ! -d "$DRUPAL_DEFAULT_DIR" ]; then
    mkdir -p "$DRUPAL_DEFAULT_DIR"
  fi
  sed -e "s/<DB>/$LOCAL_DB_DB/g" \
      -e "s/<USER>/$LOCAL_DB_USER/g" \
      -e "s/<PASS>/$LOCAL_DB_PSWD/g" \
      -e "s/<HOST>/$LOCAL_DB_HOST/g" \
      -e "s/<PREFIX>/$LOCAL_DB_PREFIX/g" \
         "$template_path" \
  >> "$slp"
  chown $USER_USER:$USER_GROUP "$slp"  # So we can edit it as our normal user

  echo '  "settings.local.php" has been created with DB information.'

  if [ -z "$(type -t 'create_db_and_user_privileges')" ]; then
    . ./db/setup_db.sh
  fi
  create_db_and_user_privileges -P
}

#
# SET OWNERSHIP ON FILE SYSTEM
#
function drupal_set_ownership() {
  function_echo_title

  if [ ! -d "$DRUPAL_ROOT" ]; then
    echo "  Drupal root does not exist. Please set it up at: $DRUPAL_ROOT"
    exit
  fi
  chown -R :$WEB_SERVER_GROUP "$DRUPAL_ROOT"
  echo "  Ownership changed recursively to: ':$WEB_SERVER_GROUP' at '$DRUPAL_ROOT'"

  local exists=0
  local line_sep='-----------------------------------------------------------------------------'
  if [ ! -e "$DRUPAL_FILES_DIR" ]; then
    echo "  $line_sep"
    echo "  DRUPAL FILES DIRECTORY DOES NOT EXIST. PLEASE SET IT UP AT: $DRUPAL_FILES_DIR"
    echo "  $line_sep"
  elif [ ! -d "$DRUPAL_FILES_DIR" ]; then
    exists=1
    echo "  $line_sep"
    echo "  DRUPAL FILES DIRECTORY IS NOT A DIRECTORY. COULD BE A LINK - FIX!: $DRUPAL_FILES_DIR"
    echo "  $line_sep"
  else
      exists=1
  fi
  if [ $exists -gt 0 ]; then
    chown -R $WEB_SERVER_USER:$USER_GROUP "$DRUPAL_FILES_DIR"
    echo "  Ownership changed recursively to: '$WEB_SERVER_USER:$USER_GROUP' at '$DRUPAL_FILES_DIR'"
  fi
}

function set_tokens_db() {
  TOKENS_DB="$SCRIPT_ROOT/drupal/data/tokens_to_restore_db"
}

function restore_user_one_password_token() {
  function_echo_title

  local uid=1

  while getopts d:l: opt; do
    case $opt in
      d) local db="$OPTARG" ;;
      l) local login="$OPTARG" ;;
    esac
  done
# shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
# OPTIND=1                # Not needed with "local OPTIND"

  if [ -z "$db" ]; then
    echo "Database missing. Please set optional parameter '-d'"
    exit
  fi
  if [ -z "$login" ]; then
    echo "--Login-path missing. Please set optional parameter '-l'"
    exit
  fi

  local name=''
  local token=''
  set_tokens_db
  if [ -e "$TOKENS_DB" ]; then
    local line=$(grep "^$login:$db:$uid:.*" "$TOKENS_DB")
    name=$( echo "$line" | cut -d':' -f4)
    token=$(echo "$line" | cut -d':' -f5)
  fi
  if [ -z "$token" ]; then
      echo "User password not found in token preservation DB."
      exit
  fi

  # Password token
  local token_esc=$(echo $token|sed -e 's/[$]/\\$/g')
  local name_esc=$( echo $name |sed -e "s/[']/\\\\'/g")
  set_LOCAL_DB_PREFIX
  local ut="${LOCAL_DB_PREFIX}users"
  mysql --login-path="$login" "$db" -e "UPDATE $ut SET name='$name_esc',pass='$token_esc' WHERE uid=1; COMMIT;"
  echo "  Login-path:$login DB:$db user 1 pass restored to : "$name', '$token
  echo
}

function rr() { # Alias
  restore_remote_user_one_pass
}
function restore_remote_user_one_pass() {
  if [ -z "$(type -t 'set_remote_db_in_mysql_config_editor')" ]; then
      . ./db/setup_db.sh
  fi
  set_remote_db_in_mysql_config_editor
  wake_up_server $REMOTE_URL $PANTHEON_KEEP_ALIVE
  restore_user_one_password_token -d "$REMOTE_DB_DB" -l "$REMOTE_DB_LOGIN_PATH"
}

function rl() { # Alias
  restore_local_user_one_pass
}
function restore_local_user_one_pass() {
  restore_user_one_password_token -d "$LOCAL_DB_DB" -l "$LOCAL_DB_LOGIN_PATH"
}

function set_user_one_password_token() {
  function_echo_title

  local OPTIND
  local uid=1

  while getopts d:h:p:P:u: opt; do
    case $opt in
      d) local db="$OPTARG" ;;
      h) local host="$OPTARG" ;;
      p) local pswd="$OPTARG" ;;
      P) local port="$OPTARG" ;;
      u) local user="$OPTARG" ;;
    esac
  done
#   shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
#   OPTIND=1                # Not needed with "local OPTIND"
  if [ -z "$db" ]; then
    echo "Database missing. Please set optional parameter '-d'"
    exit
  fi
  if [ -z "$host" ]; then
    echo "Host missing. Please set optional parameter '-h'"
    exit
  fi
  if [ -z "$pswd" ]; then
    echo "User password missing. Please set optional parameter '-p'"
    exit
  fi
  if [ -z "$port" ]; then
    echo "port missing. Please set optional parameter '-P'"
    exit
  fi
  if [ -z "$user" ]; then
    echo "User name missing. Please set optional parameter '-u'"
    exit
  fi

  #
  # Preserve current user password token and user name.
  #
  set_LOCAL_DB_PREFIX
  local ut="${LOCAL_DB_PREFIX}users"

  local result=($(mysql -u "$user" -p"$pswd" -h "$host" -P "$port" "$db" -e "SELECT name,pass FROM $ut WHERE uid=1;"))
  local cur_name="${result[${#result[@]}-2]}"
  if [ "$cur_name" == '\n' ]; then
    cur_name="${result[${#result[@]}-3]}"
  fi
  local cur_token="${result[${#result[@]}-1]}"

  local ln=''
  set_tokens_db
  if [ -e "$TOKENS_DB" ]; then
    ln=$(grep -n "^$login:$db:$uid:" "$TOKENS_DB" | cut -f1 -d:)
  fi
  if [ -z "$ln" ]; then
    echo "$login:$db:$uid:$cur_name:$cur_token" >> "$TOKENS_DB"
  else
    local answer=
    echo '  Leave & Replace will still update the Drupal DB but change'
    echo '  whether you update the DB from which the original password is'
    echo '  restored. Leave is the default. This will update the Drupal DB'
    echo '  but not change the password being stored for restoration.'
    read -t 5 -p "Password already stored. Abort/Leave(default)/Replace [a/l/r]: " answer
    case $answer in
      a) echo 'Qutting.'; exit ;;
      r) 
         local cur_token_esc=$(echo "$cur_token"|sed -e 's/[$]/\\$/g')
         sed -i  "${ln}s%.*%$login:$db:$uid:$cur_name:$cur_token_esc%" "$TOKENS_DB"
         ;;
      *) # Do not change the stored password - default 
         ;;
    esac
  fi
  echo

  #
  # Get my password token
  #
  #   We do this twice in an effort to stop getting a wrong hash which may be
  #   something to do with a new DB with all caches cleared etc.
  local phf="$DRUPAL_ROOT/scripts/password-hash.sh"
  if [ ! -e "$phf" ]; then
    echo
    echo "  Cannot get password hash because: "
    echo "    $phf"
    echo "  does not exist."
    echo
    exit
  fi
  local token=($("$phf" --root "$DRUPAL_ROOT" "$DRUPAL_ADMIN_USER_PSWD"|cut -d':' -f3))
  token="${token[${#token[@]}-1]}" # This seems to be the only easy way to get rid of the preceeding space and new line characters
  local token_esc=$(echo "$token"|sed -e 's/[$]/\\$/g')

  #
  # Set my password token in the database
  #
  mysql -u "$user" -p"$pswd" -h "$host" -P "$port" "$db" -e "UPDATE $ut SET name='$DRUPAL_ADMIN_USER_NAME', pass='$token_esc' WHERE uid = 1;"
  echo
  echo "  Host:$host DB:$db user 1 set to:"
  echo "    name='$user'"
  echo "    pass='$token'"
  echo
}

function sr() { # Alias
  set_remote_user_one_pass
}
function set_remote_user_one_pass() {
  wake_up_server $REMOTE_URL $PANTHEON_KEEP_ALIVE
  set_user_one_password_token -d "$REMOTE_DB_DB" -h "$REMOTE_DB_HOST" -p "$REMOTE_DB_PSWD" -P "$REMOTE_DB_PORT" -u "$REMOTE_DB_USER"
}

function sl() { # Alias
  set_local_user_one_pass
}
function set_local_user_one_pass() {
  set_user_one_password_token -d "$LOCAL_DB_DB" -h "$LOCAL_DB_HOST" -p "$LOCAL_DB_PSWD" -P "$LOCAL_DB_PORT" -u "$LOCAL_DB_USER"
}
