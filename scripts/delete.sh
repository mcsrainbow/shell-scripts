#!/bin/bash
 
trash_dir=${HOME}/.Trash/$(date +%Y%m%d%H%M%S)
 
function move_item(){
  full_dir=$1
  full_path=$2
  mkdir -p ${trash_dir}${full_dir}
  echo -n "Moving ${item} to ${trash_dir}${full_path}..."
  mv ${item} ${trash_dir}${full_path}
  if [[ $? -eq 0 ]]; then
    echo " Done"
  fi
}
 
if [[ $# -eq 0 ]] || $(echo "$1" |grep -Ewq '\-h|\-\-help'); then
  echo "${0} [-f] [*|FILE]"
  exit 2
fi
 
for item in $@; do
  if $(echo ${item} |grep -vq '^-'); then
    if $(echo ${item} |grep -q '^/'); then
      full_path=${item}
    else
      full_path=$(pwd)/${item}
    fi
    full_dir=$(dirname ${full_path})
    if $(echo $@ |grep -Ewq '\-f|\-rf|\-fr'); then
      move_item ${full_dir} ${full_path}
    else
      echo -n "Move ${item} to ${trash_dir}${full_path}? [y/n] "
      read yorn
      if $(echo ${yorn} |grep -Eq 'y|Y|yes|YES'); then
        move_item ${full_dir} ${full_path}
      fi
    fi
  fi
done
