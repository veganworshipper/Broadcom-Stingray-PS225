#!/bin/bash

fpath=$(cd "$(dirname "$0")"; pwd)

# import common funcs
. $fpath/efivars.sh

dris_str="OFF"
dris_support=$(($(get_efivar "bcm_dris_support") + 0))
if [ $dris_support -eq 1 ]; then
  dris_str="ON"
fi

if [ -z "$1" ]; then
  echo "DRIS is $dris_str"
  exit 0
fi

param="${1^^}"
if [ "$param" == "ON" ] && [ $dris_support -eq 1 ]; then
  echo "DRIS is already ON"
  exit 0
fi

if [ "$param" == "OFF" ] && [ $dris_support -ne 1 ]; then
  echo "DRIS is already OFF"
  exit 0
fi

if [ "$param" == "ON" ]; then
  # Check if current slots are set.
  # If so, we can continue updating.
  # If not, recovery will be initiated
  dtb_slot=$(($(get_efivar "bcm_dtb_slot") + 0))
  kernel_slot=$(($(get_efivar "bcm_kernel_slot") + 0))
  rootfs_slot=$(($(get_efivar "bcm_rootfs_slot") + 0))
  # Set DRIS ON
  set_efivar "bcm_dris_support" 1
  if [ $dtb_slot -ne 0 ] && [ $kernel_slot -ne 0 ] && [ $rootfs_slot -ne 0 ]; then
    # Explicitly set all mirrors as good
    set_efivar "bcm_bad_dtb" 0
    set_efivar "bcm_bad_kernel" 0
    set_efivar "bcm_bad_rootfs" 0
    # Fake update on current mirrors
    # so next boot bootrecovery performs
    # mirroring on other slots
    # 22=2(dtb) | 4(kernel) | 16 (rootfs)
    set_efivar "bcm_update_type" 22
    echo "Starting mirroring via Boot Recovery Service..."
    # And initiate mirroring
    ./bootrecovery.sh start
    # Done. clear bcm_update_type bits
    set_efivar "bcm_update_type" 0
   else
    echo "Because current dtb/kernel/rootfs slots are not set, Recovery will be needed"
   fi
  echo "DRIS is now ON"
else
  # Turn DRIS off
  set_efivar "bcm_dris_support" 0
  set_efivar "bcm_bad_dtb" 0
  set_efivar "bcm_bad_kernel" 0
  set_efivar "bcm_bad_rootfs" 0
  echo "DRIS is now OFF"
fi

# end of file
