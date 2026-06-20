#!/bin/bash

#set -x

fpath=$(cd "$(dirname "$0")"; pwd)

# import common funcs
. $fpath/efivars.sh

echo -e "ELOG: "
en=$(get_efivar bcm_elog_en)
if [ "$en" = "1" ]; then
  echo "enabled"
else
  echo "disabled"
fi

#end of file
