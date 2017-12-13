#!/bin/bash

function create_db_and_user_privileges() {
  function_echo_title

  local update_pwd=0
  local OPTIND
  while getopts P opt; do # We'll use capitalized options to denote updating
    case $opt in
      P) update_pwd=1 ;;  # Update the password.
    esac
  done
# shift $(($OPTIND - 1))  # Not needed unless getting positional parameters
# OPTIND=1                # Not needed with "local OPTIND"

  mysql -u "$LOCAL_DB_ADMIN_USER" -p"$LOCAL_DB_ADMIN_PSWD" -e "CREATE DATABASE IF NOT EXISTS $LOCAL_DB_DB;"

  rs=($(mysql -u "$LOCAL_DB_ADMIN_USER" -p"$LOCAL_DB_ADMIN_PSWD" -e "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$LOCAL_DB_USER') AS DB;"))
  if [ ${rs[1]} -eq 0 ]; then
    mysql -u "$LOCAL_DB_ADMIN_USER" -p"$LOCAL_DB_ADMIN_PSWD" -e "GRANT ALL PRIVILEGES ON $LOCAL_DB_DB.* TO '$LOCAL_DB_USER'@'$LOCAL_DB_HOST' IDENTIFIED BY '$LOCAL_DB_PSWD';"
    mysql -u "$LOCAL_DB_ADMIN_USER" -p"$LOCAL_DB_ADMIN_PSWD" -e 'FLUSH PRIVILEGES;'

    echo '  Local DB User created.'
  else
    echo "  Local DB User '$LOCAL_DB_USER' already exists. Updating password."
    if [ $update_pwd -gt 0 ]; then
      mysql -u "$LOCAL_DB_ADMIN_USER" -p"$LOCAL_DB_ADMIN_PSWD" -e "GRANT ALL PRIVILEGES ON $LOCAL_DB_DB.* TO '$LOCAL_DB_USER'@'$LOCAL_DB_HOST' IDENTIFIED BY '$LOCAL_DB_PSWD';"
      mysql -u "$LOCAL_DB_ADMIN_USER" -p"$LOCAL_DB_ADMIN_PSWD" -e 'FLUSH PRIVILEGES;'
    fi
  fi
}
