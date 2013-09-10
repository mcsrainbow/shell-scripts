#!/bin/bash

openvpn=/usr/sbin/openvpn
home_dir=/etc/openvpn/vpnserver
log_file=$home_dir/vpnserver.log
pid_file=$home_dir/vpnserver.pid
conf_file=$home_dir/vpnserver.ovpn

function check_root()
{
  if [ $EUID -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

function copy_vpn(){
  cmp -s $home_dir/resolv.conf.vpnserver /etc/resolv.conf
  if [ $? -ne 0 ]; then
    cp $home_dir/resolv.conf.vpnserver /etc/resolv.conf
    echo "Replaced resolv.conf as vpnserver"
  fi
}

function copy_local(){
  cmp -s $home_dir/resolv.conf.localhost /etc/resolv.conf
  if [ $? -ne 0 ]; then
    cp $home_dir/resolv.conf.localhost /etc/resolv.conf
    echo "Replaced resolv.conf as localhost"
  fi
}

function check_status(){
  nohup $home_dir/checkstatus.py > $home_dir/nohup.out 2>&1 &
}

function kill_status(){
  stauts_pid=$(ps aux | grep checkstatus.py | grep -v dong.guo | head -n 1 | awk '{print $2}')
  if [ -n "$pid" ]; then
    kill -9 $pid
  fi
}

check_root

case $1 in
  on)
    route -n | grep -q 10.20.
    if [ $? -eq 0 ]; then
      echo "Already - Connected to vpnserver"
      exit 0
    fi
    $openvpn --daemon --cd $home_dir --log $log_file --writepid $pid_file --config $conf_file --auth-nocache
    echo -n "Connecting to vpnserver"
    attempt=1
    while true
    do
      route -n | grep -q 10.20.
      if [ $? -ne 0 ]; then
        sleep 4
        echo -n "."
        if [ "$attempt" -eq 10 ]; then
          echo " FAILED"
          kill -9 `cat $pid_file`
          exit 1
        fi
      else
        echo " OK"
        copy_vpn
        check_status
        exit 0
      fi
      attempt=$(expr $attempt + 1)
    done
    ;;
  
  off)
    route -n | grep -q 10.20.
    if [ $? -ne 0 ]; then
      echo "Already - Disconnected to vpnserver"
      exit 0
    fi
    kill -9 `cat $pid_file`
    echo "Disconnected to vpnserver"
    copy_local
    kill_status
    ;;

    *)
    route -n | grep -q 10.20.
    if [ $? -ne 0 ]; then
      echo "Disconnected to vpnserver"
      copy_local
    else
      echo "OK - Connected to vpnserver"
      copy_vpn
    fi
    ;;
esac
