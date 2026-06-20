#!/bin/bash

fpath=$(cd "$(dirname "$0")"; pwd)

# import common funcs
. $fpath/efivars.sh

uefi_fw_info=$(get_efivar bcm_uefi_fw_line -c)
uefi_ver=$(get_efivar bcm_uefi_ver -c)
uefi_shell_ver=$(get_efivar bcm_uefi_shell_ver -c)

echo "$uefi_fw_info"
echo "UEFI ver. $uefi_ver"
echo "UEFI Shell ver $uefi_shell_ver"

