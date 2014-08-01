#!/bin/bash 
# http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
# Mac OS X Only

basedir=$(dirname $0)
conf="${basedir}/delegated-apnic-latest"

function check_root(){
  if [ $EUID -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

function check_conf(){
  if [ ! -f ${conf} ]; then
    echo "No such file: ${conf}"
    echo "Please download it from http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest"
    exit 1
  fi
}

function update_conf(){
  wget http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest -O ${conf}
}

function check_status(){
  netstat -rn | grep -Eq '^1.0.1/24'
  if [ $? -ne 0 ]; then
    echo "SmartRoutes is OFF"
  else
    echo "SmartRoutes is ON"
  fi
}

function add_routes(){
  oldgw=$(netstat -nr | grep '^default' | grep -v 'ppp' | sed 's/default *\([0-9\.]*\) .*/\1/' | grep -Ev '^$')
  dscacheutil -flushcache

  all_subs=$(grep CN ${conf} | grep ipv4 | awk -F '|' '{print $4"/"$5}')
  echo -n "Adding the routes..."
  for subnet in ${all_subs}
  do
    subneti=$(echo ${subnet} | cut -d/ -f1)
    rawnetm=$(echo ${subnet} | cut -d/ -f2)
    subnetm=$(awk -v c=${rawnetm} 'function log2(x){if(x<2)return(pow);pow--;return(log2(x/2))}BEGIN{pow=32;print log2(c)}')
    route add ${subneti}/${subnetm} "${oldgw}" > /dev/null
  done
  echo " Done"
}

function del_routes(){
  all_subs=$(grep CN ${conf} | grep ipv4 | awk -F '|' '{print $4"/"$5}')
  echo -n "Deleting the routes..."
  for subnet in ${all_subs}
  do
    subneti=$(echo ${subnet} | cut -d/ -f1)
    rawnetm=$(echo ${subnet} | cut -d/ -f2)
    subnetm=$(awk -v c=${rawnetm} 'function log2(x){if(x<2)return(pow);pow--;return(log2(x/2))}BEGIN{pow=32;print log2(c)}')
    route delete ${subneti}/${subnetm} > /dev/null
  done
  echo " Done"
}

function run_smartroutes(){
  netstat -rn | grep -Eq '^1.0.1/24'
  if [ $? -ne 0 ]; then
    add_routes
  else
    echo "SmartRoutes is already ON"
  fi
}

function del_smartroutes(){
  netstat -rn | grep -Eq '^1.0.1/24'
  if [ $? -eq 0 ]; then
    del_routes
  else
    echo "SmartRoutes is already OFF"
  fi
}

check_root
check_conf
case $1 in
  on)
    run_smartroutes
    ;;
  off)
    del_smartroutes
    ;;
  update)
    update_conf
    ;;
  *)
    check_status
    ;;
esac
