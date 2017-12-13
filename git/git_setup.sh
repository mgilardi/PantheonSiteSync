#!/bin/bash

function git_add_webspark_upstream_path() {
    function_echo_title

    local gfc="$DRUPAL_ROOT/.git/config"
    local ws_subdir="profiles/openasu"
    local webspark_dir="$DRUPAL_ROOT/$ws_subdir"

    if [ ! -e "$gfc" ]; then
        echo '  GIT REPO NOT FOUND!'
        return
    fi
    if [ -e "$webspark_dir" ]; then
        echo "  This has '$ws_subdir' - webspark upstream will be added to git."
    else
        echo "  '$ws_subdir' missing - webspark upstream will not be added to git."
        return
    fi
    
    if grep --quiet $GIT_WEBSPARK_UPSTREAM_LOC "$gfc"; then
        echo "  Upstream '$GIT_WEBSPARK_UPSTREAM_LOC' already added to git."
        return
    fi

    pushd "$DRUPAL_ROOT" >/dev/null
    sudo -u $USER_USER git remote add upstream "$GIT_WEBSPARK_UPSTREAM_LOC"
    popd 2>&1>/dev/null

    echo "  Added Upstream '$GIT_WEBSPARK_UPSTREAM_LOC' to git."
}
