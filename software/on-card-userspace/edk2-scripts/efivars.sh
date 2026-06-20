#!/bin/sh

GLOBAL_GUID="8be4df61-93ca-11d2-aa0d-00e098032b8c"
BRCM_VAR_GUID="c075edd3-681a-4869-8a54-606751c46f4e"

efivars_ver=2
efivars_subver=1

get_efivar ()
{
local myvar=/sys/firmware/efi/efivars/$1-$GUID

if [ "$2" == "-c" ]; then
  if [ -f "$myvar" ]; then
    myvar=$(tr -d '\0' <"$myvar")
  else
    $(exit 1)
  fi
else
  local fsize=$(($(stat -c%s "$myvar" 2>/dev/null) + 0))

  if [ $fsize -gt 0 ]; then
    fsize=$((fsize - 4))
  fi
  myvar=$(od $myvar -N $fsize -t u1 -j 4 -w 1 -An 2>/dev/null)
fi

if [ $? -eq 0 ]; then
  myvar=${myvar}
  echo $myvar
else
  echo ""
  $(exit 1)
fi
}

set_efivar ()
{
# $1 = var name
# $2 = var value
# $3 = modifiers (optional)
local cmd
local myvar=/sys/firmware/efi/efivars/$1-$GUID
local tmp="\x07\x00\x00\x00"
local char_representation=0
local tmp_var=0
local err=0
local no_nsh_update=0

if [ "$disable_nsh_update" = "1" ]; then
  no_nsh_update=1
fi

if [[ "$3" == *"c"* ]]; then
  char_representation=1
fi

if [[ "$3" == *"n"* ]]; then
  no_nsh_update=1
fi

if [[ "$3" == *"t"* ]]; then
  tmp_var=1
fi

if [ $char_representation -ne 1 ]; then
  var_modifier="-n 1"
else
  var_modifier="-c"
fi
if [ $no_nsh_update -ne 1 ] && [ $tmp_var -eq 0 ]; then
  echo "rtvar $1 $var_modifier \"$2\"" >>/tmp/run_once.nsh
  need_autorun=1
fi
if [ -f "$myvar" ]; then
  chattr -i "$myvar"
fi
if [ "$var_modifier" == "-c" ]; then
  local cmd='printf "\x07\x00\x00\x00$2" > $myvar'
else
  local hexv
  local hexval

  IFS=' ' hexv=($2)

  for v in "${hexv[@]}"; do
    hexval=$(echo "obase=16;ibase=10; $v" | bc)
    tmp="$tmp\x$hexval"
  done
  printf "$tmp" >/tmp/vartmp.bin
  cmd='cp /tmp/vartmp.bin "$myvar"'
fi
# Caller can examine $? after the next command
$(eval "$cmd" 2>/dev/null)
err="$?"
if [ $tmp_var -eq 1 ]; then
  chattr -i "$myvar"
  $(eval "rm $myvar" 2>/dev/null)
  err=$((err | $?))
fi
$(exit "$err")
}

get_next_slot ()
{
local num
local current

num=$(get_efivar "bcm_$1_slots_count")
if [ -z "$num" ]; then
  num=0
fi
current=$(get_efivar "bcm_$1_slot")
if [ -z "$current" ]; then
  current=0
fi
if [ $current -ge $num ]
then
  next=1
else
  next=$((current + 1))
fi
echo $next
}

get_cur_slot()
{
local current

current=$(get_efivar "bcm_$1_slot")
echo "$current"
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

if ! mount | grep -q "/sys/firmware/efi/efivars"; then
  check_error "mount -t efivarfs none /sys/firmware/efi/efivars"
fi

# Find out which GUID to use
GUID=$GLOBAL_GUID

set_efivar "bcm_test_tmp" 0 -t
if [ $? -ne 0 ]; then
  # GlobalVariableGuid namespace cannot be used.
  # Use BrcmVariableGuid namespace instead.
  GUID=$BRCM_VAR_GUID
fi

get_efivar_ver()
{
  echo "EFI Vars version $efivars_ver.$efivars_subver"
}

# end of file
