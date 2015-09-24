#!/bin/bash

# DNS records management tool for Bind9
# By Dong Guo from heylinux.com

base_dir="/var/named"
server_ipaddr="172.16.8.246"
domain="heylinux.com"
private_file="${base_dir}/Kheylinux.com.+157+59510.private"
dnsaddfile="${base_dir}/dnsadd"

function check_root(){
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

function print_help(){
  echo "Usage: ${0} -t A|CNAME|PTR -u add|del -n servername -v record_value"
  echo "Examples:"
  echo "${0} -t A -u add -n ns1 -v 172.16.8.246"
  echo "${0} -t A -u del -n ns1 -v 172.16.8.246"
  echo "${0} -t CNAME -u add -n ns3 -v ns1.heylinux.com"
  echo "${0} -t CNAME -u del -n ns3 -v ns1.heylinux.com"
  echo "${0} -t PTR -u add -n 172.16.8.246 -v ns1.heylinux.com"
  echo "${0} -t PTR -u del -n 172.16.8.246 -v ns1.heylinux.com"
  exit 1
}

function check_servername(){
  echo $servername | grep -wq ${domain}
  if [[ $? -eq 0 ]]; then
    hostname=$(echo $servername | cut -d. -f1)
    echo "'${servername}' is malformed. Servername should be just '${hostname}' without the '${domain}'"
    exit 1
  fi 
}

function check_fqdn(){
  echo $record_value | grep -q '\.'
  if [[ $? -ne 0 ]]; then
    echo "'${record_value}' is malformed. Should be a FQDN"
    exit 1
  fi 
}

function check_prereq(){
  # Check if the prerequisite is satisfied, such as duplicate and nonexistent
  if [[ $action == "add" ]]; then
    if [[ $record_type == "PTR" ]]; then
      echo "prereq nxrrset ${servername}.${domain} ${record_type} ${record_value}" >> ${dnsaddfile} 
    else
      echo "prereq nxdomain ${servername}.${domain}" >> ${dnsaddfile} 
    fi
  fi
  if [[ $action == "delete" ]]; then
    echo "prereq yxrrset ${servername}.${domain} ${record_type} ${record_value}" >> ${dnsaddfile} 
  fi
}

function update_record(){
  echo "server ${server_ipaddr}" >> ${dnsaddfile}
  echo "zone ${domain}" >> ${dnsaddfile}
  check_prereq
  echo "update $action ${servername}.${domain} 86400 ${record_type} ${record_value}" >> ${dnsaddfile}
  echo "send" >> ${dnsaddfile}
 
  echo "update $action ${servername}.${domain} 86400 ${record_type} ${record_value}"
  /usr/bin/nsupdate -k ${private_file} ${dnsaddfile} 

  if [[ $? -eq 0 ]]; then
    echo "Successful"
  else
    if [[ $action == "add" ]]; then
      echo "Failed because duplicate record"
    elif [[ $action == "delete" ]]; then
      echo "Failed because nonexistent/protected record"
    fi
    exit $?
  fi

  # Write DNS records into zone file immediately, by default it does every 15 minutes
  /usr/sbin/rndc freeze ${domain}
  /usr/sbin/rndc reload ${domain}
  /usr/sbin/rndc thaw ${domain}
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

if [[ -z "$record_type" ]] || [[ -z "$action" ]] || [[ -z "$servername" ]] || [[ -z "$record_value" ]]; then
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
      check_servername
      update_record
      ;;
    "CNAME")
      check_servername
      check_fqdn
      update_record
      ;;
    "PTR")
      check_fqdn
      a=$(echo $servername |cut -d. -f1 |grep -Ev '[a-z]|[A-Z]')
      b=$(echo $servername |cut -d. -f2 |grep -Ev '[a-z]|[A-Z]')
      c=$(echo $servername |cut -d. -f3 |grep -Ev '[a-z]|[A-Z]')
      d=$(echo $servername |cut -d. -f4 |grep -Ev '[a-z]|[A-Z]')
      if [[ -z "$a" ]] || [[ -z "$b" ]] || [[ -z "$c" ]] || [[ -z "$d" ]]; then
        echo "'${servername}' is malformed. Should be a IP address"
      else
        domain=$c.$b.$a.in-addr.arpa
        servername=$d
        if [[ ! -f ${base_dir}/${domain}.zone ]]; then
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
