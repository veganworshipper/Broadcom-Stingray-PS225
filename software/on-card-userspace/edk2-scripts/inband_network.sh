#!/bin/bash

help() {
  echo "Usage:"
  echo "$0 [<ip_address> <netmask> <gatewayip>]"
}

declare -a params=("IP address" "Netmask" "Gateway IP")

function validate_params() {
#$1 = ipaddr
#$2 = netmask
#$3 = gatewayip
  local orig_arr
  local array

  orig_arr=("$1" "$2" "$3")
  for (( i=0; i<${#params[@]}; i++ )); do
    IFS='.' array=(${orig_arr[$i]})
    if [ "${#array[@]}" != "4" ]; then
      $(exit $((i + 1)))
      return
    fi
    for d in ${array[@]}; do
    if [ $d -gt 255 ] || [ $d -lt 0 ]; then
      $(exit $((i + 1)))
      return
    fi
    done
  done
}

if [ "$#" -ne 3 ] && [ "$#" -ne 0 ]; then
  help
  exit 0
fi

fpath=$(cd "$(dirname "$0")"; pwd)

# import common funcs
. $fpath/efivars.sh 1>/dev/null

if [ "$#" -eq 3 ]; then
  ipaddr=${1//'.'/' '}
  netmask=${2//'.'/' '}
  gw=${3//'.'/' '}
  validate_params "$1" "$2" "$3"
  err=$?
  if [ $err -eq 0 ]; then
    set_efivar "bcm_inband_ipaddr" "$ipaddr"
    set_efivar "bcm_inband_netmask" "$netmask"
    set_efivar "bcm_inband_gatewayip" "$gw"
    echo "Set In-Band parameters (IP address $1; netmask $2; gateway: $3)"
  else
    echo "Invalid parameter \"${params[$((err - 1))]}\""
  fi
else
  IFS=' ' ia=($(get_efivar bcm_inband_ipaddr))
  IFS=' ' nm=($(get_efivar bcm_inband_netmask))
  IFS=' ' gw=($(get_efivar bcm_inband_gatewayip))
  ipaddr=${ia[@]}
  netmask=${nm[@]}
  gw=${gw[@]}
  ipaddr="${ipaddr//' '/.}"
  netmask="${netmask//' '/.}"
  gw="${gw//' '/.}"
  validate_params "$ipaddr" "$netmask" "$gw"
  err=$?
  if [ $err -eq 0 ]; then
    # Callee will be using array to retrieve parameters
    echo "$ipaddr"
    echo "$netmask"
    echo "$gw"
  else
    echo "Invalid In-Band IP configuration parameter \"${params[$((err - 1))]}\""
    exit 1
  fi
fi
if [ "$need_autorun" == "1" ] && [ "$#" == "3" ]; then
  if ! mount | grep -q /mnt; then
    check_error "mount -t vfat /dev/mmcblk0p1 /mnt"
  fi
  check_error "cp -f /tmp/run_once.nsh /mnt/run_once.nsh"
  umount /mnt 2>/dev/null
fi
