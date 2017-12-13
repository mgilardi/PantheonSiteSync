#!/bin/bash

function setup_config_file() {
    if [ ! -e "$PROJECT_ROOT" ]; then
        sudo -u $USER_USER mkdir "$PROJECT_ROOT"
    fi
    if [ ! -e "$CONFIG_FILE" ]; then
        sudo -u $USER_USER cp './initialize/templates/config.template' "$CONFIG_FILE"
        sudo -u $USER_USER $USER_EDITOR "$CONFIG_FILE"
    fi
}

function process_config_file_variables() {
    REMOTE_PANTHEON_DASHBOARD_URL_RAW="$REMOTE_PANTHEON_DASHBOARD_URL"
    REMOTE_PANTHEON_DASHBOARD_URL=$(echo "$REMOTE_PANTHEON_DASHBOARD_URL" | sed -e 's/#.*//g')
    REMOTE_UUID=$(basename $REMOTE_PANTHEON_DASHBOARD_URL)

    #
    # HEADER
    #
    echo
    echo "PROCESSING: Config File"

    #
    # DRUPAL
    #
    if [ -z "$DRUPAL_GIT_CLONE" ]; then
        # On Test and Live servers as git connections string is not available.
        DRUPAL_ROOT=$(find "$PROJECT_ROOT" -type l)
        ENV=$(echo "$REMOTE_PANTHEON_DASHBOARD_URL_RAW" | grep -oP '#\w+');
        ENV=${ENV:1}
        if [ -z "$DRUPAL_ROOT" ]; then
            # We can make this up because git will never set it.
            DRUPAL_ROOT=$PROJECT_ROOT/$(basename $PROJECT_ROOT)
        fi
    else
        DRUPAL_ROOT="$PROJECT_ROOT/"$(echo "$DRUPAL_GIT_CLONE" | cut -d' ' -f4)
        ENV=$(echo "$DRUPAL_GIT_CLONE" | cut -d'.' -f2)
    fi
    if [ -z "$DRUPAL_ROOT" ]; then
        echo "Could not determine DRUPAL_ROOT."
        exit
    fi

    DRUPAL_DEFAULT_DIR="$DRUPAL_ROOT/sites/default"
    DRUPAL_FILES_DIR="$DRUPAL_DEFAULT_DIR/files"

    # From documentation
    #   The problem with this is that it was downloading a link instead of the 
    #   files.
    #   DRUPAL_FILES_SOURCE="${ENV}.${REMOTE_UUID}@appserver.${ENV}.${REMOTE_UUID}.drush.in:code/sites/default/files"
    # Suggested workaround - note the removal of: code/sites/default/
    #   This now downloads the files like it should.
    DRUPAL_FILES_SOURCE="${ENV}.${REMOTE_UUID}@appserver.${ENV}.${REMOTE_UUID}.drush.in:files"

    #
    # WEB SERVER
    #
    LOCAL_DOMAIN_BASE=$(echo "$REMOTE_URL" | cut -d'-' -f2- | sed -e 's%/%%g' -e 's/\.ws\.asu\.edu$//g')
    LOCAL_DOMAIN=$LOCAL_DOMAIN_BASE-${ENV}.local
    echo "  Local domain: $LOCAL_DOMAIN"

    #
    # DATABASE
    #

    # REMOTE
    REMOTE_DB_USER=$(echo "$REMOTE_DB_LINE" | cut -d' ' -f3)
    REMOTE_DB_PSWD=$(echo "$REMOTE_DB_LINE" | cut -d' ' -f4 | cut -c3-)
    REMOTE_DB_HOST=$(echo "$REMOTE_DB_LINE" | cut -d' ' -f6)
    REMOTE_DB_PORT=$(echo "$REMOTE_DB_LINE" | cut -d' ' -f8)
      REMOTE_DB_DB=$(echo "$REMOTE_DB_LINE" | cut -d' ' -f9)

    # LOCAL
    hm=$HOME
    HOME="/$USERS_BASE_PATH/$USER_USER"

    if [ -e "$DRUPAL_DEFAULT_DIR/settings.local.php" ]; then
      LOCAL_DB_PSWD=$(grep -oP "['\"]password['\"]\s*=>\s*['\"].*['\"]" "$DRUPAL_DEFAULT_DIR/settings.local.php" |cut -d"'" -f4)
    else
      LOCAL_DB_PSWD=$(sudo -u $USER_USER openssl rand -hex 10)
    fi

    HOME=$hm
    len=$(($LOCAL_DB_DB_NAME_LEN_MAX - ${#ENV} - 1))
    LOCAL_DB_DB=$(echo "$LOCAL_DOMAIN_BASE" | tr '.-' '_' | cut -c 1-${len}|sed 's/_$//')_${ENV}
    LOCAL_DB_USER=$LOCAL_DB_DB
    echo "  Local dtbase: $LOCAL_DB_DB"

}
