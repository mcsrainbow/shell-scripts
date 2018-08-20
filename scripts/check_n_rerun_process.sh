#!/bin/bash
#
# Nagios style check script for Process Check and Rerun
# By Dong Guo
#

function print_help(){
  echo "Usage: ${0} -p 'ps_string_for_Program' -n proc_num -r 'rerun_cmd' [-m max_rerun]"
  echo "Examples:"
  echo "${0} -p 'kafka.Kafka' -n 1 -r 'service kafka-server start'"
  echo "${0} -p 'kafka.Kafka' -n 1 -r 'service kafka-server start' -m 3"
  exit 1
}

function check_n_rerun(){
  run_proc_num=$(ps aux | grep -w "${proc_grep}" | grep -Ewv "nohup|grep|${base_name}" | wc -l | xargs)
  if [[ ${run_proc_num} -eq ${proc_num} ]];then
    echo "OK"
    echo 0 > ${rerun_count_sign}
    exit 0
  elif [[ ${run_proc_num} -gt ${proc_num} ]];then
    echo "UNKN. ${run_proc_num} running '${proc_grep}', expected: ${proc_num}"
    exit 3
  elif [[ ${run_proc_num} -lt ${proc_num} ]];then
    rerun_count=$(cat ${rerun_count_sign})
    if [[ ${rerun_count} -lt ${max_rerun} ]];then
      sudo ${rerun_cmd}
      rerun_count=$((${rerun_count}+1))
      echo ${rerun_count} > ${rerun_count_sign}
      echo "WARN. ${run_proc_num} running '${proc_grep}', expected: ${proc_num}, rerun: ${rerun_count}/${max_rerun}"
      exit 1
    else
      echo "CRIT. ${run_proc_num} running '${proc_grep}', expected: ${proc_num}, rerun: ${rerun_count}/${max_rerun}"
      exit 2
    fi
  fi
}

while getopts "p:n:r:m:" opts; do
  case "$opts" in
    "p")
      proc_grep=$OPTARG
      ;;
    "n")
      proc_num=$OPTARG
      ;;
    "r")
      rerun_cmd=$OPTARG
      ;;
    "m")
      max_rerun=$OPTARG
      ;;
    *)
      print_help
      ;;
  esac
done

if [[ -z "$proc_grep" ]] || [[ -z "$proc_num" ]] || [[ -z "$rerun_cmd" ]]; then
  print_help
else
  base_name=$(basename ${0})
  proc_grep_formatted=$(echo "${proc_grep}" | sed 's/\//_/g' | sed 's/ /_/g')
  rerun_count_sign=/var/tmp/${proc_grep_formatted}.max_rerun.count
  if [[ ! -f ${rerun_count_sign} ]];then
    echo 0 > ${rerun_count_sign}
  fi
  if [[ -z "$max_rerun" ]]; then
    max_rerun=3
  fi
  check_n_rerun
fi
