#!/bin/bash

TX_FILE_FOR_BG_PROCESSES="logs/varsToTx.sh" # This we have to hard code since this is a spawned process and all variables have been lost.
if [ -e "$TX_FILE_FOR_BG_PROCESSES" ]; then
  . "./$TX_FILE_FOR_BG_PROCESSES"
fi
. $1 $2 $3 $4 $5 $6 $7 $8 $9
