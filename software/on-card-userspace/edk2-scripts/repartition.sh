#!/bin/bash

MD5SUM_FILE=md5sum.txt
TFTP_BLOCKSIZE=1468
DD_BLOCKSIZE=4096
args="$*"
serverip=192.168.1.20
dir=nic
image="part.txt"
transport=tftp

# device name
BLOCK_DEVICE=mmcblk0

# Target Partition information
declare -a target_part_name
declare -a target_part_size
# default dual partition scheme
target_part_scheme=2

# script path
fpath=$(cd "$(dirname "$0")"; pwd)
# import common funcs
. $fpath/efivars.sh

function usage ()
{
  echo "args=$args"
  echo
  echo "repartition.sh -s <serverip> -d <dir> -i <image> -t <transport>"
  echo
  echo "Helper script, used to repartition emmc"
  echo
  echo " -s <serverip>    IPv4 address of http or tftp server"
  echo " -d <dir>         Directory under the top-level TFTP or HTTP server directory"
  echo " -t <transport>   Transport (tftp or http)"
  echo
}

function check_error ()
{
  if [ "$1" != "" ]; then
    eval "$1"
  else
    return 0
  fi
  err=$?
  if [ $err -ne 0 ]; then
    echo "ERROR: Exiting on error $err; command \"$1\""
    exit $err
  fi
}

function md5Check()
{
  # Input parameters:
  # file for which md5sum is being verified
  # md5sum list for all files
  # The function calculates md5sum of the input file
  # and verifies whether this md5sum exists in the md5sum list

  if [ -z "$1" -o -z "$2" ];then
    echo "Error: input file and md5sum list file should be provided"
    exit 1
  fi

  if [ ! -f "$1" ];then
    echo "Error: input file doesn't exit"
    exit 1
  fi

  if [ ! -f "$2" ];then
    echo "Error: md5sum list file doesn't exit"
    exit 1
  fi

  fileToCheck=$1
  md5sumList=$2
  md5MatchFound=0

  md5Input=`md5sum $fileToCheck|cut -c -32`
  # echo md5Input = $md5Input

  while read line
  do
    md5lineInFile=`echo $line|cut -c -32`
    # echo line = $md5lineInFile
    if [ "$(echo "$md5lineInFile" | tr -d '[:space:]')" = "$(echo "$md5Input" | tr -d '[:space:]')" ]; then
    echo "Found matching md5 sum ($md5Input)"
    md5MatchFound=1
    break
    fi
  done < $md5sumList

  if [ $md5MatchFound = 0 ];then
    echo "md5sum match not found!!! Exiting"
    md5MatchFound=0
    # Unmount the /mnt partition if mounted
    umount /mnt 2>/dev/null
    exit
  fi
}

function parse_part_info()
{
  if [ ! -f "$1" ];then
    echo "Error: input file doesn't exit"
    exit 1
  fi

  part_file=$1

  index=0
  while read line
  do
    if [[ $line =~ ^Part\,(.+) ]]; then
      part_name=`echo $line | cut -d, -f2`
      part_size=`echo $line | cut -d, -f3 | sed 's/\"//g'`
      target_part_name[$index]=$part_name
      target_part_size[$index]=$part_size
      index=$(($index+1))
    fi
    if [[ $line =~ ^Rootfs(.+)([0-9]+)(.+) ]]; then
      target_part_scheme="${BASH_REMATCH[2]}"
    fi
  done < $part_file

  # print part info
  echo "---------------------"
  target_part_num=${#target_part_name[@]}
  for ((i=0; i<$target_part_num; i++)); do
    echo "${target_part_name[$i]} ${target_part_size[$i]}"
  done
  echo "target_part_scheme: ${target_part_scheme}"
  echo "---------------------"
}

# Recovery partition is "LinuxRoot"
# Return:
#    0 - Error
#    n - repartition start position
function check_recovery_rootfs()
{
  recovery_name=$(lsblk /dev/mmcblk0 -no partlabel | grep -x LinuxRoot)
  recovery_pos=
  repart_start_pos=

  if [ -z "$recovery_name" ]; then
    # No recovery
    repart_start_pos=2
  else
    # check whether if current partition is recovery
    recovery_pos=2
    cur_part=$(lsblk | grep "/$")
    if [[ $cur_part =~ .+\mmcblk0p([0-9]+)\ (.+) ]]; then
      part_no="${BASH_REMATCH[1]}"
      if [[ $part_no -eq $recovery_pos ]]; then
        repart_start_pos=$(($recovery_pos+1))
      else
        repart_start_pos=0
      fi
    fi
  fi

  return $repart_start_pos
}

# Main Start ...

# First check dependencies
check_recovery_rootfs
ret=$?
if [[ $ret -eq 0 ]]; then
  echo "-- Error: Current partition is not recovery."
  echo "   Please switch to recovery rootfs and then rerun it"
  exit 1
else
  target_part_start=$ret
  echo "Repartition starts from $target_part_start"
fi

while [[ $# -gt 0 ]]; do
  option="$1"

  case $option in
  -s)
  if [ "$2" = "" ];then
    usage
    exit 1
  fi
  serverip=$2
  shift
  shift
  ;;

  -d)
  if [ "$2" = "" ];then
    usage
    exit 1
  fi
  dir=$2
  shift
  shift
  ;;

  -t)
  if [ "$2" = "" ];then
    usage
    exit 1
  fi
  transport=$2
  shift
  shift
  ;;

  -f)
  if [ "$2" = "" ];then
    usage
    exit 1
  fi
  # skip -f option used by repartition.sh to fetch script
  shift
  shift
  ;;

  *)
  echo "---> Error: invalid image args"
  usage
  exit 1
  shift
  ;;

  esac
done

echo
echo "Parameters"
echo "----------"
echo "serverip:     $serverip"
echo "directory:    $dir"
echo "image:        $image"
echo "transport:    $transport"

# Verify no parameter is empty
if [ "$serverip" = "" -o "$dir" = "" -o "$image" = "" -o "$transport" = "" ]; then
  echo
  echo "---> Error: parameters missing. Check the command line."
  usage
  exit 1
fi

# Verify the transport option
if [ "$transport" != "tftp" -a "$transport" != "http" -a "$transport" != "https" ]; then
  echo
  echo "---> Error: invalid transport option"
  usage
  exit 1
fi
if [ "$transport" == "https" ]; then
  httpsuffix="s"
fi

echo
echo "Log"
echo "---"

echo "Fetching $MD5SUM_FILE"
if [ "$transport" = "tftp" ]; then
  check_error "tftp -b $TFTP_BLOCKSIZE -g -r $dir/$MD5SUM_FILE -l /tmp/$MD5SUM_FILE $serverip"
elif [ "$transport" = "http" -o "$transport" = "https" ]; then
  check_error "wget http$httpsuffix://$serverip/$dir/$MD5SUM_FILE -O /tmp/$MD5SUM_FILE"
else
  echo "---> Error: invalid transport option"
  exit 1
fi

echo "Fetching $image"
if [ "$transport" = "tftp" ]; then
  check_error "tftp -b $TFTP_BLOCKSIZE -g -r $dir/$image -l /tmp/$image $serverip"
elif [ "$transport" = "http" -o "$transport" = "https" ]; then
  check_error "wget http$httpsuffix://$serverip/$dir/$image -O /tmp/$image"
else
  echo "---> Error: invalid transport option"
  exit 1
fi
md5Check /tmp/$image /tmp/$MD5SUM_FILE

# Parse part.txt and get partition info
echo "Parse $image"
parse_part_info /tmp/$image

# Go query parted
# Extract the partition information
parted_info=$(parted --script /dev/$BLOCK_DEVICE unit MiB print)
# default offset 1MiB
# Handle aligned issue
default_offset=1

declare -a part_start
declare -a part_end
part_table_type=
part_no=
last_partition=0
while read -r line; do
  if [[ $line =~ ^Partition\ Table:\ (.+) ]]; then
    part_table_type="${BASH_REMATCH[1]}"
    echo "part_table_type $part_table_type"
    echo "------------"
    continue
  fi
  if [[ $line =~ ^([0-9]+)\ +([0-9.]+)MiB\ +([0-9]+).+ ]]; then
    part_no="${BASH_REMATCH[1]}"

    part_start[$part_no]="${BASH_REMATCH[2]}"
    part_end[$part_no]="${BASH_REMATCH[3]}"
    echo "part_no $part_no"
    echo "part_start ${part_start[$part_no]}"
    echo "part_end ${part_end[$part_no]}"
    echo "------------"
    continue
  fi
done <<< "$parted_info"
last_partition=$part_no

# 1 - ESP
# 2 - Recovery or Rootfs
target_part_num=${#target_part_size[@]}
for ((i=$target_part_start; i<$last_partition+1; i++)); do
  parted --script /dev/$BLOCK_DEVICE rm $i
done

# Repartion
for ((i=$target_part_start; i<$target_part_num+1; i++)); do
  start="${part_end[$i-1]}"
  if [[ $i == $target_part_start ]]; then
    start="$((${part_end[$i-1]}+$default_offset))"
  fi
  part_start[$i-1]=$start
  if [[ $i -eq $target_part_num ]]; then
    parted -a opt --script /dev/$BLOCK_DEVICE mkpart ${target_part_name[$i-1]} ext4 "${start}MiB" 100%
  else
    end="$((${part_end[$i-1]}+${target_part_size[$i-1]}))"
    parted -a opt --script /dev/$BLOCK_DEVICE mkpart ${target_part_name[$i-1]} ext4 "${start}MiB" "${end}MiB"
  fi
  mkfs.ext4 -F /dev/mmcblk0p$i
  part_end[$i]=$end
  echo "PartNo $i ${start}MiB - ${end}MiB"
done
parted --script /dev/$BLOCK_DEVICE unit MiB print

# Configure partition scheme
set_efivar "bcm_rootfs_slots_count" ${target_part_scheme}

# Avoid kernel crash because of no rootfs partition:
#   1. if power off at this stage
#   2. if reboot at this stage

# Keep recovery mode after repartition
set_efivar "bcm_boot_recovery" 1

# Always delete bcm_rootfs_ordinal
#   If bcm_rootfs_ordinal is not equal to rootfs_next_slot,
#   next upgrade will lead to kernel crash.
set_efivar "bcm_rootfs_ordinal"

# save run_once.nsh to ESP
umount /mnt 2>/dev/null
# Mount the FAT32 ESP Partition to write the run_once.nsh
if ! mount | grep -q /mnt; then
  check_error "mount -t vfat /dev/mmcblk0p1 /mnt"
fi
check_error "cp -f /tmp/run_once.nsh /mnt/run_once.nsh"
umount /mnt 2>/dev/null

echo "Repartition is done. Please reboot or go on upgrade."

# end of file
