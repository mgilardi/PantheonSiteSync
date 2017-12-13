#!/bin/bash

function add_vhosts() {
    function_echo_title

    local changed=0

    if generate_ssl_cert; then
      changed=1;
    fi

    if grep -P --quiet "use\s+Vhost\s+${LOCAL_DOMAIN}" "$WEB_SERVER_VHOST"; then
      echo "      vHosts file already set with domain: $LOCAL_DOMAIN"
    else
      sed -e "s/<LOCAL_DOMAIN>/$LOCAL_DOMAIN/g" \
             "./$SCRIPT_PATH/templates/apache24_vhost-and-ssl-macro.template" \
      >> "$WEB_SERVER_VHOST"

      echo "  $LOCAL_DOMAIN added to vhosts file."
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

    if [ -e "$WEB_SERVER_FILES/$LOCAL_DOMAIN/www" ]; then
      echo "  Apache Docs folder already linked to project."
    else
      local cwd=$(pwd)
      if [ ! -e "$WEB_SERVER_FILES/$LOCAL_DOMAIN" ]; then
        mkdir -p "$WEB_SERVER_FILES/$LOCAL_DOMAIN"
      fi
      cd "$WEB_SERVER_FILES/$LOCAL_DOMAIN"
      ln -s "$DRUPAL_ROOT" www
      cd "$cwd"
      echo "  Apache Docs folder linked to project."
      changed=1
    fi

    if [ $changed -gt 0 ]; then
      local hm="$HOME"
      HOME="/$USERS_BASE_PATH/$USER_USER"
      apachectl -k restart
      HOME="$hm"
      echo "  Apache restarted due to Apache config changes."
    fi
}
