#!/bin/bash

SCRIPT_PATH=$(dirname "${BASH_SOURCE[0]}")
. ./$SCRIPT_PATH/generate_ssl_cert.sh

if [ -z "$SCRIPT_ROOT" ]; then
    if [ -z "$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR" ]; then
      PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR=PantheonSiteSync
    fi
    SCRIPT_ROOT=$(realpath "${BASH_SOURCE[0]}"|grep -o "^.*$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR")
    cd "$SCRIPT_ROOT"
    . ./initialize/initialize.sh -i "minimal" -q "$PROJECT_NAME_QUERY"
fi

. ./web-server/variants/apache24-with-macros-linux.sh
