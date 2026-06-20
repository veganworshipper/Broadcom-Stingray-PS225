#!/bin/sh

#set -x

version=$1

install_ebtables() {
  # enable and start ebtables.service
  systemctl enable ebtables.service
  systemctl start ebtables.service
}

set_ebtables_rules() {
  local network=172.16.0.0/30

  ebtables -t filter -F

  ebtables -t filter -A INPUT -i bond0 -p arp --arp-ip-src $network -j DROP
  ebtables -t filter -A INPUT -i bond0 -p arp --arp-ip-dst $network -j DROP

  ebtables -t filter -A FORWARD -p arp --arp-ip-src $network -j DROP
  ebtables -t filter -A FORWARD -p arp --arp-ip-dst $network -j DROP

  ebtables -t filter -A OUTPUT -o bond0 -p arp --arp-ip-src $network -j DROP
  ebtables -t filter -A OUTPUT -o bond0 -p arp --arp-ip-dst $network -j DROP

  # save rules for next reboot
  ebtables -t filter --atomic-file /etc/sysconfig/ebtables.filter --atomic-save
}

set_ebtables_rules

service=`systemctl status ebtables.service`
if [ $? -eq 0 ]; then
  # Enabled service by default
  # Check whether if it's brought up successfully
  echo $service | grep -E "inactive|FAILED"
  if [ $? -eq 0 ]; then
    # If fail reintstall it
    install_ebtables
  fi
else
  # No service and reinstall it
  install_ebtables
fi

# end of file
