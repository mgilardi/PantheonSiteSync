#!/bin/bash

if echo "$DRUPAL_GIT_CLONE" | grep -q "^mysql "; then
  echo "The variable DRUPAL_GIT_CLONE seems to have a MySQL connection string. Please check the config file."
  exit
fi

if [ ${#DRUPAL_GIT_CLONE} -eq 0 ]; then
  echo "The variable DRUPAL_GIT_CLONE seems to empty."
  exit
fi

# This way if we are reinstalling rapidly we don't keep redownloading the 
# database. This probably is only really needed while testing the scripts.
# We put this first because it's slow so starting it first makes sense.

#
# DNS
#
. ./dns/hosts.sh
update_hosts_file

#
# MYSQL DB
#
. ./db/setup_db.sh
create_db_and_user_privileges

if [ -z "$(find $SQL_DIR -cmin -20 -name '*.sql')" ]; then
   . ./includes/spawn.sh "./db/download_remote_db.sh" -a -q "$PROJECT_NAME_QUERY"
fi

#
# DRUPAL FILES
#
. ./drupal/drupal_setup.sh
drupal_get_git_files

. ./includes/spawn.sh "./drupal/rsync_remote_files_dir.sh" -a -q "$PROJECT_NAME_QUERY"

waiting_for_process_to_end rsync
if [ $WAITED -eq 0 ]; then
  echo '  Something went wrong with rsync, quitting.'
  exit
fi

set_settings_php_file
set_settings_local_php_file
drupal_set_ownership

#
# GIT MODIFICATIONS
#
. ./git/git_setup.sh
git_add_webspark_upstream_path

#
# WEB SERVER
#
. ./web-server/apache.sh
add_vhosts

#
# SUMMARY
#
echo
echo "PROCESSED: Install"
echo "  Local URL's:"
echo "       http://$LOCAL_DOMAIN"
echo "      https://$LOCAL_DOMAIN"
echo "       http://www.$LOCAL_DOMAIN"
echo "      https://www.$LOCAL_DOMAIN"
echo
echo "   Local DB: $LOCAL_DB_DB"
echo

TASK_START_TIME=$INSTALL_TOTAL_START_TIME
set_task_start_time  -s 'total install time'
show_tasks_duration

echo
echo "$GLOBAL_SEP"
echo
