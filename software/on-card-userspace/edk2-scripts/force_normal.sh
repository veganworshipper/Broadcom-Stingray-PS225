#!/bin/bash

#set -x

fpath=$(cd "$(dirname "$0")"; pwd)

# import common funcs
. $fpath/efivars.sh

# condition 1:
# if bcm_boot_count < bcm_max_boot_count, enter into normal mode
# Do not modify bcm_max_boot_count
set_efivar "bcm_boot_count" "0"

# condition 2:
# if bcm_boot_recovery has already configured
# Clear it.
set_efivar "bcm_boot_recovery" "0"

# Unmount the /mnt partition if mounted
umount /mnt >/dev/null
# Mount the FAT32 ESP Partition to write the autorun.nsh
if ! mount | grep -q /mnt; then
  mount -t vfat /dev/mmcblk0p1 /mnt
fi
cp -f /tmp/run_once.nsh /mnt/run_once.nsh
umount /mnt 2>/dev/null

echo "Please reboot and enter into normal mode"
