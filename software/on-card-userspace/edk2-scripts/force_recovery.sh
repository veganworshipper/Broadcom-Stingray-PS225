#!/bin/bash

#set -x

fpath=$(cd "$(dirname "$0")"; pwd)

# import common funcs
. $fpath/efivars.sh

# setting bcm_boot_recovery will force entering Recovery
set_efivar "bcm_boot_recovery" 1

echo "Please reboot to enter Recovery mode"
