#!/bin/bash

TX_FILE_FOR_BG_PROCESSES="$LOG_DIR/varsToTx.sh"
function save_vars_and_join_display() {
  xauth add $(xauth -f /home/$USER_USER/.Xauthority list|tail -1)
  export DISPLAY=:0.0
  export XDG_RUNTIME_DIR='/tmp/runtime-root'
  # The information to derive USER_GROUP & USER_USER gets lost when spawning
  # which we get from "who am i" in bash.
  set |grep -P '^(USER_(USER|GROUP)|PROJECT_NAME_QUERY)=' > "$TX_FILE_FOR_BG_PROCESSES"
  chmod 775 "$TX_FILE_FOR_BG_PROCESSES"
  chown $USER_USER:$USER_GROUP "$TX_FILE_FOR_BG_PROCESSES" # Just to make it easier to delete if we want.
}

case "$(uname -s)" in
    Linux*)
      case $(echo "$XDG_DATA_DIRS" | grep -Po 'gnome|kde|xfce' | head -n1) in
        gnome) 
          save_vars_and_join_display
          gnome-terminal -e "./includes/spawned.sh $1 $2 $3 $4 $5 $6 $7 $8 $9" & # Not yet tested
        ;;
        kde)
          save_vars_and_join_display
          konsole --noclose -e "./includes/spawned.sh $1 $2 $3 $4 $5 $6 $7 $8 $9" &
        ;;
        xfce) echo 'Not implemented.' ;;
      esac
    ;;

    Darwin*)
osascript<<EOF
  tell application "Terminal"
    do script "cd \"`pwd`\"; $1 $2 $3 $4 $5 $6 $7 $8 $9"
  end tell
EOF
    ;;
#    CYGWIN*) ;;
#    MINGW*)  ;;
#    *)       ;;
esac
