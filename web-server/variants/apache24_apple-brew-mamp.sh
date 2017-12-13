#!/bin/bash

function add_vhosts() {
    function_echo_title

    local changed=0

    if generate_ssl_cert; then
        changed=1;
    fi

    if grep --quiet "/$LOCAL_DOMAIN/" "$WEB_SERVER_VHOST"; then
        echo "      vHosts file already set with domain: $LOCAL_DOMAIN"
    else
        sed -e "s/<LOCAL_DOMAIN>/$LOCAL_DOMAIN/g" \
            -e "s/<SERVER_ADMIN>/$USER_MAIL/g" \
            -e "s%<APACHE_LOG_FILES>%$WEB_SERVER_LOG_FILES%g" \
               "./$SCRIPT_PATH/templates/apache24-vhost.template" \
        >> "$WEB_SERVER_VHOST"

        echo "  $LOCAL_DOMAIN added to vhosts file."
        changed=1
    fi

    if grep --quiet "/$LOCAL_DOMAIN/" "$WEB_SERVER_SSL"; then
        echo "  SSL vHosts file already set with domain: $LOCAL_DOMAIN"
    else
        sed -e "s/<LOCAL_DOMAIN>/$LOCAL_DOMAIN/g" \
            -e "s%<APACHE_LOG_FILES>%$WEB_SERVER_LOG_FILES%g" \
               "./$SCRIPT_PATH/templates/apache24-ssl.template" \
        >> "$WEB_SERVER_SSL"

        echo "  $LOCAL_DOMAIN added to SSL vhosts file."
        changed=1
    fi

    local lfd="$WEB_SERVER_LOG_FILES/$LOCAL_DOMAIN"
    if [ -d "$lfd" ]; then
        echo "  Log files directory already created at: $lfd"
    else
        mkdir "$lfd"
        echo "  Log files directory created at: $lfd"
        changed=1
    fi

    if [ -e "$WEB_SERVER_FILES/$LOCAL_DOMAIN" ]; then
        echo "  Apache Docs folder already linked to project."
    else
        local cwd=$(pwd)
        cd "$WEB_SERVER_FILES"
        ln -s "$DRUPAL_ROOT" "$LOCAL_DOMAIN"
        cd "$cwd"
        echo "  Apache Docs folder linked to project."
        changed=1
    fi

    if [ $changed -gt 0 ]; then
        local hm=$HOME
        HOME=/$USERS_BASE_PATH/$USER_USER

        # Use whichever of the two below works on your system. I'm doing both
        # just to be sure as there's something funky going on.
        apachectl -k restart
        sudo -u $USER_USER brew services restart httpd24

        HOME=$hm
        echo "  Apache restarted due to Apache config changes."
    fi
}
