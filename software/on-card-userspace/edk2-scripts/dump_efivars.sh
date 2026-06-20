#!/bin/bash

fpath=$(cd "$(dirname "$0")"; pwd)

# import common funcs
. $fpath/efivars.sh

cd /sys/firmware/efi/efivars || exit 1

IFS=$'\n' vars=($(ls bcm_*-$GUID))
echo "${#vars[@]} variable(s)"
echo "Raw dump:"
echo " "
for var in ${vars[@]}; do
  var=${var/-$GUID/}
  IFS=' ' value=($(get_efivar $var))
  if [ ${#value[@]} -eq 1 ]; then
    echo -e "$var = \"${value[@]}\""
  else
    echo ">$var (${#value[@]} bytes)"
    echo -e "\tBytes: ${value[@]}"
    echo -e -n "\t"
    echo "String: \"$(get_efivar $var -c)\""
  fi
done
echo "------------------------------"

echo "Next slots:"
echo " "

dtb_next_slot=$(($(get_next_slot "dtb") + 0))
echo "dtb_next_slot=$dtb_next_slot"

kernel_next_slot=$(($(get_next_slot "kernel") + 0))

echo "kernel_next_slot=$kernel_next_slot"

rootfs_next_slot=$(($(get_next_slot "rootfs") + 0))
echo "rootfs_next_slot=$rootfs_next_slot"

# end of file
