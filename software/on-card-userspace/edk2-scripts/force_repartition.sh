#!/bin/bash

#set -x
rootfs_num=$1
if [ -z $rootfs_num ]; then
  rootfs_num=2
fi
if [ $rootfs_num -eq 1 ] || [ $rootfs_num -eq 2 ]; then
  echo "Partition scheme: $rootfs_num"
else
  # use default dual partition scheme
  rootfs_num=2
fi

fpath=$(cd "$(dirname "$0")"; pwd)

# import common funcs
. $fpath/efivars.sh

# setting bcm_boot_recovery will force entering Recovery
set_efivar "bcm_boot_recovery" 1

# bcm_rootfs_slots_count
#   single_partition: 1
#   dual_partition  : 2
set_efivar "bcm_rootfs_slots_count" $rootfs_num

echo "Please reboot to enter Repartition mode"
