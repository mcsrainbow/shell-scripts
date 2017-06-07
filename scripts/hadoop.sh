#!/bin/bash

# List all protected directories here
# For example:
#   To protect all the directories in /user and the directory /user, use "/user/*"
#   To protect the directory /user/dong/workspace and its parent directory /user/dong, use "/user/dong/workspace"
#
# NOTE: "/*" is not allowed in "protected_dirs"

protected_dirs=(
/user/*
/user/oozie/*
/user/dong/workspace
/rawlogs
)

hadoop_cmd="/usr/bin/hadoop"

function generate_detailed_protected_dirs(){
  for dir_item in ${protected_dirs[@]}; do
    if [[ "${dir_item}" =~ "*" ]]; then
      dir_path=$(/usr/bin/dirname "${dir_item}")
      detailed_dir_item=$(${hadoop_cmd} fs -ls "${dir_path}" | grep '^dr' | awk '{print $NF}')
    else
      detailed_dir_item="${dir_item}"
    fi
    detailed_protected_dirs="${detailed_protected_dirs} ${detailed_dir_item}"
  done

  echo "${detailed_protected_dirs}"
}

if [[ "$1" == "fs" ]]; then
  detailed_protected_dirs=$(generate_detailed_protected_dirs)
  if [[ "$2" =~ "rm" ]]; then
    dir_items="${@:3}"
    for dir_item in ${dir_items}; do
      if [[ "${dir_item}" != "-*" ]]; then
        detailed_protected_dirs_list=$(echo "${detailed_protected_dirs}" | xargs -n1)
        if $(echo "${detailed_protected_dirs_list}" | grep -wq "^${dir_item}"); then
          echo "ERROR: The directory \"${dir_item}\" is PROTECTED, PLEASE DO NOT DELETE IT."
          return_value=2
        fi
      fi
    done
  fi
fi

if [[ ! -z "${return_value}" ]]; then
  exit ${return_value}
fi

${hadoop_cmd} ${@:1}
