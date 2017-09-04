#!/bin/bash

function print_help(){
  echo "Usage:"
  echo "  ${0} show"
  echo "  ${0} /user/root/.Trash/Current"
  exit 2
}

if [[ -z "$1" ]];then
  print_help
fi

if [[ "$1" == "show" ]];then
  hadoop fs -du -h /user/*/.Trash | awk '($2=="T") {print}' | sort -rn
  exit 0
fi

if ! $(echo "$1" | grep -Eq "/user/.*/.Trash/"); then
  print_help
else
  hadoop fs -rm -r $1
fi
