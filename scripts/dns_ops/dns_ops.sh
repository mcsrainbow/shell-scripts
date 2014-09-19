#!/bin/bash

base_dir=/var/named
server_ipaddr=172.16.8.246
domain=heylinux.com
private_file=${base_dir}/Kheylinux.com.+157+59510.private
dnsaddfile=${base_dir}/dnsadd

function check_root()
{
  if [ $EUID -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

function print_help(){
  echo "Usage: ${0} -t A|CNAME|PTR -u add|del -n servername -v record_value"
  echo "${0} -t A -u add -n ns1 -v 172.16.8.246"
  echo "${0} -t A -u del -n ns1 -v 172.16.8.246"
  echo "${0} -t CNAME -u add -n ns3 -v ns1.heylinux.com"
  echo "${0} -t CNAME -u del -n ns3 -v ns1.heylinux.com"
  echo "${0} -t PTR -u add -n 172.16.8.246 -v ns1.heylinux.com"
  echo "${0} -t PTR -u del -n 172.16.8.246 -v ns1.heylinux.com"
  exit 1
}


function update_record(){
  echo "server ${server_ipaddr}" >> ${dnsaddfile}
  echo "zone ${domain}" >> ${dnsaddfile}
  echo "update $action ${servername}.${domain} 86400 ${record_type} ${record_value}" >> ${dnsaddfile}
  echo "send" >> ${dnsaddfile}
  
  /usr/bin/nsupdate -k ${private_file} ${dnsaddfile} 

  if [ $? -eq 0 ]; then
    echo "Successful"
  else
    echo "Failed because duplicate/nonexistent record"
    exit $?
  fi

  /usr/sbin/rndc freeze ${domain}
}

check_root
while getopts "t:u:n:v:" opts
do
  case "$opts" in
    "t")
      record_type=$OPTARG
      ;;
    "u")
      action=$OPTARG
      ;;
    "n")
      servername=$OPTARG
      ;;
    "v")
      record_value=$OPTARG
      ;;
    *)
      print_help
      ;;
  esac
done

if [ -z "$record_type" ] || [ -z "$action" ] || [ -z "$servername" ] || [ -z "$record_value" ]; then
  print_help
else
  > ${dnsaddfile}
  case "$action" in 
    "add")
      action=add
      ;;
    "del")
      action=delete
      ;;
    *)
      print_help
      ;;  
  esac
  case "$record_type" in 
    "A")
      update_record
      ;;
    "CNAME")
      update_record
      ;;
    "PTR")
      a=$(echo $servername |cut -d. -f1)
      b=$(echo $servername |cut -d. -f2)
      c=$(echo $servername |cut -d. -f3)
      d=$(echo $servername |cut -d. -f4)
      if [ -z "$a" ] || [ -z "$b" ] || [ -z "$c" ] || [ -z "$d" ]; then
        print_help
      else
        domain=$c.$b.$a.in-addr.arpa
        servername=$d
        if [ ! -f ${base_dir}/${domain}.zone ]; then
          echo ${base_dir}/${domain}.zone does not exist
          exit 1 
        else
          update_record
        fi
      fi
      ;;
    *)
      print_help
      ;;  
  esac 
fi
