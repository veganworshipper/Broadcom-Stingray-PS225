#!/bin/bash

PCIE_DEV_ID="[16f0\|d802\|d804]"
PCIE_VENDOR_ID="14e4"

#
# Get the first available interface name for PCIE functions
#
function get_nitro_interface_name() {
  for index in {0..8..1}; do
    LSPCI_F0_FULL_LINE=$(lspci -d $PCIE_VENDOR_ID:|grep "\.${index}.*Eth.*${PCIE_DEV_ID}")
    if [ "$?" -ne  "0" ]; then
      echo "Nitro interfaces not available. Cannot program Nitro"
      exit
    fi
    BUSIDF0=$(echo "$LSPCI_F0_FULL_LINE"|awk '{print $1}')
    DEV_ID=$(echo "$LSPCI_F0_FULL_LINE"|awk '{print $7}')
    INTERFACE_NAME_F0=$(ls -l /sys/class/net | grep "$BUSIDF0" | awk '{print $9}')
    # if unbind from bnxt_en, continue to find next available eth device
    if [ -z "$INTERFACE_NAME_F0" ]; then
      continue
    fi

    # Check link up if boards only have nitro interfaces.
    # Otherwise report warning.
    ifconfig "$INTERFACE_NAME_F0" up >/dev/null 2>&1
    ethtool "$INTERFACE_NAME_F0" | grep "Link detected: yes" >/dev/null 2>&1
    link_status=$?
    if [ "$DEV_ID" = "d802" ]; then
      if [ $link_status -eq 0 ]; then
        break
      fi
    else
      if [ $link_status -ne 0 ]; then
        echo "Warning: $INTERFACE_NAME_F0 link down."
      fi
      break
    fi
  done
}

fpath=$(cd "$(dirname "$0")"; pwd)

# UEFI ver
echo
echo "UEFI:"
$fpath/show_uefi_ver.sh

# FW ver
echo
echo "FW:"
get_nitro_interface_name
ethtool -i $INTERFACE_NAME_F0

# ELOG feature
echo
$fpath/check_elog_en.sh

# end of file
