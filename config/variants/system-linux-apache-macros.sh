#!/bin/bash

#
# File system paths
#
HOSTS_FILE="/etc/hosts"
USERS_BASE_PATH="/home"
PROJECTS_ROOT="$USERS_BASE_PATH/reg/Jobs/PHP/Drupal/TekSystems/ASU"

#
# rsync
#
RSYNC_PROCESSES_MAX=16
RSYNC_BATCH_SIZE=300

#
# APACHE WEB SERVER
#
WEB_SERVER_USER=wwwrun
WEB_SERVER_GROUP=www

WEB_SERVER_ETC="/etc/apache2"
WEB_SERVER_CERTS="/etc/ssl/private"
WEB_SERVER_VHOST="$WEB_SERVER_ETC/vhosts.d/vhosts/vhosts-single-site.list"

WEB_SERVER_LOG_FILES="/var/log/apache2"
WEB_SERVER_FILES="/srv/www/vhosts"

#
# MYSQL DB
#
LOCAL_DB_ADMIN_USER="root"
LOCAL_DB_ADMIN_PSWD="F6zrHLJThQ4gsVGv"

LOCAL_DB_HOST="localhost"
LOCAL_DB_PORT="3306"

LOCAL_DB_DB_NAME_LEN_MAX=31
