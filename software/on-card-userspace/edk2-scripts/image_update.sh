#!/bin/bash

MD5SUM_FILE=md5sum.txt
TFTP_BLOCKSIZE=1468
DD_BLOCKSIZE=4096

GLOBAL_GUID="8be4df61-93ca-11d2-aa0d-00e098032b8c"
BRCM_VAR_GUID="c075edd3-681a-4869-8a54-606751c46f4e"

declare -a flash_options=('all' 'dtb' 'fip' 'kernel' 'noroot' 'rootfs')

get_efivar ()
{
local myvar=$(od /sys/firmware/efi/efivars/$1-$GUID  -N 1 -t u1 -j 4 -w 1 -An 2>/dev/null)
if [ $? -eq 0 ]; then
  myvar=${myvar}
  echo $myvar
else
  echo ""
fi
}

set_efivar ()
{
local myvar=/sys/firmware/efi/efivars/$1-$GUID
if [ -f $myvar ]; then
  chattr -i $myvar
fi
hexval=`echo "obase=16;ibase=10; $2" | bc`
local cmd='printf "\x07\x00\x00\x00\x$hexval" > $myvar'
$(eval $cmd 2>/dev/null)
}

get_next_slot ()
{
local num=$(get_efivar bcm_$1_slots_count)
if [ -z $num ]; then
  num=0
fi
local current=$(get_efivar bcm_$1_slot)
if [ -z $current ]; then
  current=0
fi
if [ $current -ge $num ]
then
  next=1
else
  next=$((${current}+1))
fi
echo $next
}

usage ()
{
  echo
  echo "image_update.sh -s <serverip> -d <dir> -i <image> -t <transport>"
  echo
  echo "Helper script, used to flash one or more of the requested images to emmc."
  echo "A reboot, after flashing, must be performed for the new images to take effect."
  echo
  echo " -s <serverip>  IPv4 address of http or tftp server"
  echo " -d <dir>       Directory under the top-level TFTP or HTTP server directory"
  echo " -i <image>     Image can take one of the following values"
  echo "                   all       Copies all files, dtb, fip, kernel and rootfs"
  echo "                   dtb       Copies dtb only"
  echo "                   fip       Copies fip only"
  echo "                   kernel    Copies fip kernel only"
  echo "                   noroot    Copies fip, dtb and kernel, no rootfs"
  echo "                   rootfs    Copies rootfs only"
  echo " -t <transport> Transport (tftp or http)"
  echo
}

check_error ()
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

while [[ $# -gt 0 ]]; do
  option="$1"

  case $option in
  -i)
  if [ "$2" = "" ];then
    usage
    exit 1
  fi
  image=$2
  shift
  shift
  ;;

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

  esac
done

echo
echo "Parameters"
echo "----------"
echo "serverip:  $serverip"
echo "directory: $dir"
echo "image:     $image"
echo "transport: $transport"

# Verify no parameter is empty
if [ "$serverip" = "" -o "$dir" = "" -o "$image" = "" -o "$transport" = "" ]; then
  echo
  echo "---> Error: parameters missing. Check the command line."
  usage
  exit 1
fi

# Verify the flash option
flash_opt=$image
if ! [[ ${flash_options[*]} =~ $flash_opt ]]; then
  echo
  echo "---> Error: invalid image option"
  usage
  exit 1
else
  echo "flash_opt: $flash_opt"
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


if ! mount | grep -q "/sys/firmware/efi/efivars"; then
  check_error "mount -t efivarfs none /sys/firmware/efi/efivars"
fi

# Find out which GUID to use
GUID=$GLOBAL_GUID
err=$(ls /sys/firmware/efi/efivars/bcm*-$GLOBAL_VAR_GUID 2>/dev/null)
if [ $? -ne 0 ]; then
  # Error on the previous command does not necessarily mean BrcmVariableGuid
  # namespace needs to be used.
  # Still theoretically there is a chance all bcm* vars were deleted in
  # GobalVariableGuid namespace.
  # So try to actually create a variable bcm_boot count in GlobalVariableGuid
  # namespace. If this fails, that means GlobalVariableGuid
  # namespace is protected, and standard VariableRuntimDxe driver is being used.
  # Therefore we use BrcmVariableGuid namespace.
  set_efivar "bcm_boot_count" "0"
  if [ $? -ne 0 ]; then
    # GlobalVariableGuid namespace cannot be used.
    # Use BrcmVariableGuid namespace instead.
    GUID=$BRCM_VAR_GUID
  fi
fi
if [ $GUID == $GLOBAL_GUID ]; then
  echo "Using variable namespace GLOBAL ($GUID)"
else
  echo "Using variable namespace BRCM ($GUID)"
fi

boot_count=$(get_efivar "bcm_boot_count")
if [ -z boot_count ]; then
  boot_count=0
fi
echo "boot_count=$boot_count"

# Mount the FAT32 ESP Partition to write the Kernel and DTB
if ! mount | grep -q /mnt; then
  check_error "mount -t vfat /dev/mmcblk0p1 /mnt"
fi

if [ $flash_opt = "dtb" ] || [ $flash_opt = "all" ] || [ $flash_opt = "noroot" ]
then
  dtb_slot=$(get_next_slot "dtb")
  echo "dtb_slot=$dtb_slot"
  echo "Fetching dt-blob.bin"
  if [ "$transport" = "tftp" ]; then
    check_error "tftp -b $TFTP_BLOCKSIZE -g -r $dir/dt-blob.bin -l /mnt/dt-blob.bin.$dtb_slot $serverip"
  elif [ "$transport" = "http" -o "$transport" = "https" ]; then
    check_error "wget http$httpsuffix://$serverip/$dir/dt-blob.bin -O /mnt/dt-blob.bin.$dtb_slot"
  else
    echo "---> Error: invalid transport option"
    exit 1
  fi
  md5Check /mnt/dt-blob.bin.$dtb_slot /tmp/$MD5SUM_FILE

  set_efivar "bcm_dtb_slot" $dtb_slot
  if [ $? -ne 0 ]; then
    echo "ERROR - could not set bcm_dtb_slot variable"
  fi
fi

if [ $flash_opt = "kernel" ] || [ $flash_opt = "all" ] || [ $flash_opt = "noroot" ]
then
  kernel_slot=$(get_next_slot "kernel")
  echo "kernel_slot=$kernel_slot"
  echo "Fetching Image"
  if [ "$transport" = "tftp" ]; then
    check_error "tftp -b $TFTP_BLOCKSIZE -g -r $dir/Image -l /mnt/Image.$kernel_slot $serverip"
  elif [ "$transport" = "http" -o "$transport" = "https" ]; then
    check_error "wget http$httpsuffix://$serverip/$dir/Image -O /mnt/Image.$kernel_slot"
  else
    echo "---> Error: invalid transport option"
    exit 1
  fi
  md5Check /mnt/Image.$kernel_slot /tmp/$MD5SUM_FILE

  set_efivar "bcm_kernel_slot" $kernel_slot
  if [ $? -ne 0 ]; then
    echo "ERROR - could not set bcm_kernel_slot variable"
  fi

fi

# Now mount a TMPFS to code the FIP and rootfs
umount /mnt >/dev/null
check_error "mount -t tmpfs -o size=1g none /mnt"
check_error "cd /mnt"

if [ $flash_opt = "fip" ] || [ $flash_opt = "all" ] || [ $flash_opt = "noroot" ]
then
  echo "TFTP fip.bin"
  if [ "$transport" = "tftp" ]; then
    check_error "tftp -b $TFTP_BLOCKSIZE -g -r $dir/fip.bin $serverip"
  elif [ "$transport" = "http" -o "$transport" = "https" ]; then
    check_error "wget http$httpsuffix://$serverip/$dir/fip.bin"
  else
    echo "---> Error: invalid transport option"
    exit 1
  fi
  md5Check /mnt/fip.bin /tmp/$MD5SUM_FILE

  # Program new FIP image to BP1
  echo "write fip.bin to BP1 - offset by 0x20000"
  echo 0 > /sys/block/mmcblk0boot0/force_ro
  check_error "dd if=fip.bin of=/dev/mmcblk0boot0 bs=512 seek=256"
  echo 1 > /sys/block/mmcblk0boot0/force_ro
  rm fip.bin

fi

if [ $flash_opt = "rootfs" ] || [ $flash_opt = "all" ]
then
  # Update ROOTFS partition in next slot
  rootfs_slot=$(get_next_slot "rootfs")
  echo "rootfs_slot=$rootfs_slot"
  rootfs_partition=$((${rootfs_slot}+2))
  echo "rootfs_partition=$rootfs_partition"
  echo "Fetching service info"
  offsets_filename="offsets.txt"
  if [ "$transport" = "tftp" ]; then
    check_error "tftp -b $TFTP_BLOCKSIZE -g -r $dir/rootfs/$offsets_filename $serverip"
  elif [ "$transport" = "http" -o "$transport" = "https" ]; then
    check_error "wget http$httpsuffix://$serverip/$dir/rootfs/$offsets_filename"
  else
    echo "---> Error: invalid transport option"
    exit 1
  fi
  md5Check $offsets_filename /tmp/$MD5SUM_FILE
  l_count=$(wc -l < "$offsets_filename")
  chunk_count=$(($l_count - 2))
  if [ $chunk_count -le 0 ]; then
    echo "Invalid $offsets_filename file. Exiting."
    exit 1
  fi
  echo "ROOTFS chunks count: $chunk_count"
  # Remove all quotes first
  sed -i 's/\"//g' $offsets_filename

  declare -a l_array
  n=0

  while IFS='' read -r line || [[ -n "$line" ]]; do
    IFS=',' read -a l_array <<< "$line"
    if [ "${l_array[0]}" == "Offset" ]; then
      n=$((n + 1))
      chunk_name="${l_array[1]}"
      seek="${l_array[2]}"
      echo "CHUNK $n/$chunk_count, offset $seek, slot $rootfs_slot"

      echo "Fetching ROOTFS"
      if [ "$transport" = "tftp" ]; then
            check_error "tftp -b $TFTP_BLOCKSIZE -g -r $dir/rootfs/$chunk_name $serverip"
      elif [ "$transport" = "http" -o "$transport" = "https" ]; then
            check_error "wget http$httpsuffix://$serverip/$dir/rootfs/$chunk_name $serverip"
      else
        echo "---> Error: invalid transport option"
        exit 1
      fi
      md5Check $chunk_name /tmp/$MD5SUM_FILE

      echo "Writing ROOTFS"
      # Offsets are provided based on 512-byte block size. We need to recalculate the seek value based on DD_BLOCKSIZE
      check_error "dd if=$chunk_name of=/dev/mmcblk0p$rootfs_partition bs=$DD_BLOCKSIZE seek=$((seek*512/$DD_BLOCKSIZE)) status=progress"

      rm $chunk_name
    fi
  done < "$offsets_filename"

  set_efivar "bcm_rootfs_slot" $rootfs_slot
  if [ $? -ne 0 ]; then
    echo "ERROR - could not set bcm_rootfs_slot variable"
  fi

fi

set_efivar "bcm_boot_count" "0"
if [ $? -ne 0 ]; then
  echo "ERROR - could not set bcm_boot_count variable"
fi


echo
echo "Please reboot for the change to take effect"
echo
