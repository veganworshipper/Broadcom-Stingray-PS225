#!/bin/bash

fpath=$(cd "$(dirname "$0")"; pwd)

if [ -z "$SHARED_LIB_DIR" ]
then
  SHARED_LIB_DIR=$fpath
fi

if [ -f "$SHARED_LIB_DIR/error_codes.sh" ]
then
  . "$SHARED_LIB_DIR/error_codes.sh"
else
  upd_result_filename="$SHARED_LIB_DIR/last_updateme_result.txt"
  warn_start=60
fi

if [ "$1" != "" ]; then
  upd_result_filename="$1"
fi

# Set error to "general failure" if result file does not exist
err=1
if [ -f "$upd_result_filename" ]; then
  # Getting result and info
  IFS=$'\n' lines=($(cat "$upd_result_filename"))
  echo -e "Code: ${lines[0]}\nMessage: ${lines[1]}\nTimeStamp: ${lines[2]}"
  err="${lines[0]}"
else
  echo "$upd_result_filename not found."
fi

if [ $err -eq 0 ]; then
  $fpath/get_cur_version.sh
fi

exit $err
