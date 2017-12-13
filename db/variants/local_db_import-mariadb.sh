#!/bin/bash

function set_drupal_admin_user_password() {
    function_echo_title

    if [ -z "$DRUPAL_ROOT" ]; then
        echo '  Could not set Drupal admin user password because DRUPAL_ROOT not set.'
        return
    fi

    if [ -z "$DRUPAL_ADMIN_USER_PSWD" ]; then
        echo '  Drupal admin user password not set defined. Go to header.sh and define it.'
        return
    fi

    set_LOCAL_DB_PREFIX
    local ut="${LOCAL_DB_PREFIX}users"

    # Password token
    token=($("$DRUPAL_ROOT/scripts/password-hash.sh" --root "$DRUPAL_ROOT" $DRUPAL_ADMIN_USER_PSWD|cut -d':' -f3))
    token="${token[${#token[@]}-1]}" # This seems to be the only easy way to get rid of the preceeding space and new line characters
    token_esc=$(echo "$token"|sed -e 's/[$]/\\$/g')
    local name_esc=$(echo "$DRUPAL_ADMIN_USER_NAME"|sed -e "s/[']/\\\\'/g")
    mysql -u "$LOCAL_DB_USER" -p"$LOCAL_DB_PSWD" -h "$LOCAL_DB_HOST" -P "$LOCAL_DB_PORT" "$LOCAL_DB_DB" -e "UPDATE $ut SET name='$name_esc',pass='$token_esc' WHERE uid=1; COMMIT;"

    echo '  Drupal admin user password set to variable DRUPAL_ADMIN_USER_PSWD which is defined in user.sh.'
}

function local_db_import() {
    function_echo_title
    if [ -n "$(mysql -u "$LOCAL_DB_USER" -p"$LOCAL_DB_PSWD" -h "$LOCAL_DB_HOST" -P "$LOCAL_DB_PORT" -e "SHOW DATABASES;" 2>&1 | grep 'ERROR')" ]; then
        if [ -z "$(type -t 'create_db_and_user_privileges')" ]; then
            . ./db/setup_db.sh
        fi
        create_db_and_user_privileges -P
    fi

    local sql=$(basename $1)

    pv "$1" | mysql -u "$LOCAL_DB_USER" -p"$LOCAL_DB_PSWD" -h "$LOCAL_DB_HOST" -P "$LOCAL_DB_PORT" "$LOCAL_DB_DB"
    echo "  SQL file '$sql' imported into '$LOCAL_DB_DB'"

    set_drupal_admin_user_password
}

local_db_import "$sql"
