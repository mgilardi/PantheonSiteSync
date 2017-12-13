#!/bin/bash

#
# Sample host line: 
#   127.0.0.1       chs2.ws.asu.edu-dev.local www.chs2.ws.asu.edu-dev.local
#
function update_hosts_file() {
    function_echo_title

    re="127.0.0.1[[:space:]]\+$LOCAL_DOMAIN[[:space:]]\+www.$LOCAL_DOMAIN"
    if grep --quiet "$re" "$HOSTS_FILE"; then
        echo "  Hosts file already set with domain: $LOCAL_DOMAIN"
        return
    fi
    local line="127.0.0.1       $LOCAL_DOMAIN  www.$LOCAL_DOMAIN"
    echo  "  Add to '$HOSTS_FILE': $line"
    echo  "$line" >> "$HOSTS_FILE"
}
