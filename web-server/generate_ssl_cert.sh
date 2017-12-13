#!/bin/bash

if [ -z "$USER_MAIL" ]; then
  . ./includes/common.sh
  get_user_and_group
  . ./config/user.sh
fi
if [ -z "$WEB_SERVER_CERTS" ]; then
  . ./config/system.sh
fi

. ./web-server/variants/generate_ssl_cert_apache24-with-macros-linux.sh

#
# Do getopts before calling any in-line scripts in case they look for positional parameters
#
while getopts d: opt; do
  case $opt in
    d)  LOCAL_DOMAIN="$OPTARG";
      if [[ $LOCAL_DOMAIN == www.* ]]; then
        echo "Domain should not start with 'www.'."
        exit
      fi
      generate_ssl_cert;
    ;;
  esac
done
#shift $(($OPTIND - 1)) # Not needed unless getting positional parameters
OPTIND=1                # Not needed with "local OPTIND"
