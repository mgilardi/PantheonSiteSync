#!/bin/bash

#
# File system paths
#
HOSTS_FILE="/private/etc/hosts"
USERS_BASE_PATH="/Users"
PROJECTS_ROOT="$USERS_BASE_PATH/regproctor/Jobs"

#
# rsync
#
RSYNC_PROCESSES_MAX=16
RSYNC_BATCH_SIZE=300

#
# APACHE WEB SERVER
#
WEB_SERVER_USER=daemon
WEB_SERVER_GROUP=daemon

WEB_SERVER_ETC="/usr/local/etc/apache2/2.4"
WEB_SERVER_CERTS="$WEB_SERVER_ETC/certs"
WEB_SERVER_VHOST="$WEB_SERVER_ETC/extra/httpd-vhosts.conf"
WEB_SERVER_SSL="$WEB_SERVER_ETC/extra/httpd-ssl.conf"
WEB_SERVER_LOG_FILES="/private/var/log/apache2"
WEB_SERVER_FILES="/usr/local/var/www/htdocs"

#
# MYSQL DB
#
LOCAL_DB_ADMIN_USER="root"
LOCAL_DB_ADMIN_PSWD=""

LOCAL_DB_LOGIN_PATH=local
LOCAL_DB_DB_NAME_LEN_MAX=31
