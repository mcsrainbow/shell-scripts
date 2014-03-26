#!/bin/bash
# 
# Bootstrap Script for Hostname,Network...
# 
# Author: Dong Guo
# Last Modified: 2013/10/24 by Dong Guo

options=$(cat /proc/cmdline|sed 's/.*rhgb quiet  //g')
config=/etc/sysconfig/network-scripts/ifcfg-eth0
failed=/root/bootstrap.failed

function check_root(){
  if [ $EUID -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
  fi
}

function configure_os(){
  echo "DEVICE=eth0" > $config
  echo "ONBOOT=yes" >> $config
  echo "BOOTPROTO=none" >> $config
  
  for i in $options
  do
    option=$(echo $i|cut -d "=" -f 1)
    value=$(echo $i|cut -d "=" -f 2)
    if [ "${option:0:1}" = "_" ]; then
      case "$option" in
        _hostname)
         oldname=$(hostname)
         newname=$value
         sed -i s/"$oldname"/"$newname"/g /etc/sysconfig/network
         hostname $newname
        ;;
        _ipaddr)
         echo "IPADDR=$value" >> $config
        ;;
        _netmask)
         echo "NETMASK=$value" >> $config
        ;;
        _gateway)
         echo "GATEWAY=$value" >> $config
        ;;
      esac
    fi
  done
}

function restart_network(){
  /etc/init.d/network restart
}

function check_status(){
  gateway=$(grep -w GATEWAY $config|cut -d "=" -f 2)
  route -n | grep -wq $gateway
  if [ $? -eq 0 ]; then
    sed -i /bootstrap/d /etc/rc.local
    if [ -a $failed ]; then
      rm -f $failed
    fi
  else
    touch $failed
  fi
}

check_root
configure_os
restart_network
check_status
