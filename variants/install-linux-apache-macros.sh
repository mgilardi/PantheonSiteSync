#!/bin/bash

if echo "$REMOTE_PANTHEON_DASHBOARD_URL_RAW" | grep -Pq '(test|live)'; then
  echo
  echo "  You cannot perform an install on a Test or Live server."
  echo "  You will probably want to symlink the dev version's Drupal directory"
  echo "  to this one so that MySQL password functions work. I.e. rr(), sr(), rl(), sl()."
  echo "  Also, clone the local Dev DB to '$LOCAL_DB_DB'. for rl(), sl()."
  echo
  exit
fi
