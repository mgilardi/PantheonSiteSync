#!/bin/bash

GLOBAL_SEP="---------------------------------------------------------------------------"
echo
echo "$GLOBAL_SEP"
echo

INSTALL_TOTAL_START_TIME=$(date +%s)

if [ "$(whoami)" != 'root'  ]; then
  echo 'Please run this as root user.'
  exit
fi

PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR=automation
if [ -z "$SCRIPT_ROOT" ]; then
  if [ -z "$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR" ]; then
    PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR=automation
  fi
  SCRIPT_ROOT=$(realpath "${BASH_SOURCE[0]}"|grep -o "^.*$PANTHEON_DOWNLOAD_AUTOMATION_SCRIPT_ROOT_DIR")
  cd "$SCRIPT_ROOT"
  . ./initialize/initialize.sh
fi

. ./variants/install-linux-apache-macros.sh
. ./includes/install-end-part.sh
