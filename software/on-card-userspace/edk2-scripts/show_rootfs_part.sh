#!/bin/bash

recovery_pos=2
cur_part=$(lsblk | grep "/$")
if [[ $cur_part =~ .+\mmcblk0p([0-9]+)\ (.+) ]]; then
  part_no="${BASH_REMATCH[1]}"
  if [[ $part_no -eq $recovery_pos ]]; then
    echo -n "Recovery Partition: "
  else
    echo -n "Normal Partition: "
  fi
  lsblk /dev/mmcblk0p$part_no -no partlabel
fi

# end of file
