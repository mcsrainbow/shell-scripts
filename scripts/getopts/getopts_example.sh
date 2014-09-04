#!/bin/bash

function print_help(){
  echo "Usage: ${0} -u username -p password [ -h hostname ]"
  exit 1
}

while getopts "u:p:h:" opts
do
  case "$opts" in
    "u")
      username=$OPTARG
      ;;
    "p")
      password=$OPTARG
      ;;
    "h")
      hostname=$OPTARG
      ;;
    "*")
      print_help
      ;;
  esac
done

if [ -z "$username" ] || [ -z "$password" ]; then
  print_help
else
  echo "Username: $username  Password: $password"
fi

if [ ! -z "$hostname" ]; then
  echo "Hostname: $hostname"
fi
