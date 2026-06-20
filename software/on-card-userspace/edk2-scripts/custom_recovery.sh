#!/bin/bash

PCIE_DEV_ID="[16f0\|d802\|d804]"
PCIE_VENDOR_ID="14e4"

#
# Get the interface names for PCIE functions
#
function get_nitro_interface_name() {
  pf_index="$1"
  LSPCI_F0_FULL_LINE=`lspci -d $PCIE_VENDOR_ID:|grep "\.${pf_index}.*Eth.*${PCIE_DEV_ID}"`
  if [ "$?" -ne  "0" ]; then
    echo "Nitro interfaces not available. Cannot program Nitro"
    exit
  fi
  BUSIDF0=`echo $LSPCI_F0_FULL_LINE|awk '{print $1}'`
  INTERFACE_NAME_F0=`ls -l /sys/class/net | grep $BUSIDF0 | awk '{print $9}'`
}

#
# Check whether if it's legacy eth name
#
function check_legacy_ethname()
{
  ethname=$1
  if [[ $ethname =~ ^eth([0-9]+) ]]; then
    legacy_ethname=1
  else
    legacy_ethname=0
  fi
}

#
# wait for non-legacy ethname
#
function get_non_legacy_ethname()
{
  intf_id=$1
  i=0
  while [ $i -lt 10 ]; do
    get_nitro_interface_name $intf_id
    pf_eth=$INTERFACE_NAME_F0
    check_legacy_ethname $pf_eth
    if [ $legacy_ethname -eq 0 ]; then
      break
    else
      sleep 1
      i=$(($i+1))
    fi
  done
}

get_non_legacy_ethname 2
pf2=$pf_eth
echo $i

get_non_legacy_ethname 3
pf3=$pf_eth
echo $i

get_non_legacy_ethname 4
pf4=$pf_eth
echo $i

get_non_legacy_ethname 5
pf5=$pf_eth
echo $i

echo $pf2
echo $pf3
echo $pf4
echo $pf5

#
# create bond interface
#
create_bond() {
  local bond_name=$1
  local pf2=$2
  local pf3=$3

  bond_mod=`lsmod | grep "bonding"`
  if [ -z $bond_mod ]; then
    modprobe bonding
  fi
  is_existed=`ip link show | grep "$bond_name"`
  if [ ! -z $is_existed ]; then
    ip link del dev $bond_name
  fi

  echo "Add $bond_name "
  ip link add name $bond_name type bond
  ip link set dev $bond_name type bond mode 802.3ad
  ip link set dev $bond_name type bond miimon 100
  ip link set dev $bond_name type bond lacp_rate slow
  ip link set dev $bond_name type bond xmit_hash_policy layer3+4
  ip link show

  ifconfig $pf2 down
  ifconfig $pf3 down
  echo "+$pf2" > /sys/class/net/$bond_name/bonding/slaves
  echo "+$pf3" > /sys/class/net/$bond_name/bonding/slaves
  ifconfig $bond_name up
  ifconfig $pf2 up
  ifconfig $pf3 up
}

# create bond0 with pf2 and pf3
bond0_name="bond0"
create_bond $bond0_name $pf2 $pf3

fpath=$(cd "$(dirname "$0")"; pwd)
IFS=$'\n' inband_params=($($fpath/inband_network.sh))
if [ $? -ne 0 ]; then
  # create bond1 with pf4 and pf5
  bond1_name="bond1"
  create_bond $bond1_name $pf4 $pf5

  # no default cfg
  # establish bridge
  echo "no default cfg"
  br_existed=`brctl show | grep 'br-default'`
  if [ ! -z $br_existed ]; then
    ifconfig br-default down
    brctl delbr br-default 1>/dev/null
  fi
  brctl addbr br-default 1>/dev/null

  brctl addif br-default $bond0_name 1>/dev/null
  brctl addif br-default $bond1_name 1>/dev/null
  brctl show

  ifconfig $bond0_name 0
  ifconfig $bond1_name 0

  ifconfig br-default 172.16.0.2 netmask 255.255.255.252 up

  sshd_port=22
else
  echo "setup bonding..."
  # setup bonding
  # bonding interface
  # In-band parameters have been retrieved and are accessible as:
  # ${inband_params[0]} - IP addr
  # ${inband_params[1]} - netmask
  # ${inband_params[2]} - gatewayip
  ipaddr=${inband_params[0]}
  netmask=${inband_params[1]}
  gw=${inband_params[2]}
  echo $ipaddr
  echo $netmask
  echo $gw

  ifconfig $bond0_name $ipaddr netmask $netmask

  ip route add default via $gw

  sshd_port=36000
fi

# modify sshd.socket port if necessary
egrep -q "ListenStream=$sshd_port" /lib/systemd/system/sshd.socket || {
  sed -i "s/^ListenStream=.*$/ListenStream=$sshd_port/g" /lib/systemd/system/sshd.socket
  systemctl daemon-reload
  systemctl restart sshd.socket
}

# customzied ebtables 
/usr/share/edk2/custom_ebtables.sh

# end of file
