#!/bin/bash

logfiles=(
/blog/logs/foo_access.log
/blog/logs/bar_access.log
)

whitelist=$(last | awk '{print $3}' | grep ^[1-9] | sort | uniq | xargs)
whitelist+=" 127.0.0.1 10.1.2.3 1.2.3.4"

function check_root(){
  if [ $EUID -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
  fi
}

function block_ips(){
  blacklist=$@
  if [ ! -z "${blacklist}" ]; then
    for ip in ${blacklist}
    do
      if ! $(echo ${whitelist} | grep -wq ${ip}); then
        if ! $(/sbin/iptables-save | grep -wq ${ip}); then
          echo "Blocked ${ip}"
          /sbin/iptables -I INPUT -s ${ip}/32 -p tcp -m tcp --dport 80 -j DROP
        fi
      fi
    done
  fi
}

function check_post(){
  page=$1
  tailnum=$2
  retry=$3

  command="grep -w POST ${logfile} |tail -n ${tailnum} |grep -w ${page} |awk '{print \$1}' |sort |uniq -c |awk '(\$1 > ${retry}){print \$2}'"
  blacklist=$(eval ${command})
  block_ips ${blacklist}
}

function check_all(){
  tailnum=$1
  retry=$2

  command="tail -n ${tailnum} ${logfile} |awk '{print \$1}' |sort |uniq -c |awk '(\$1 > ${retry}){print \$2}'"
  blacklist=$(eval ${command})
  block_ips ${blacklist}
}

check_root
for logfile in ${logfiles[@]}
do
  check_post wp-login.php 10000 50
  check_post wp-comments-post.php 10000 50
  check_all 10000 500
done
