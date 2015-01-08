#!/bin/bash

if [ $# -ne 1 ]; then
  echo Usage:
  echo "${0} <timeout_second>"
  echo Example:
  echo "${0} 540"
  exit 1 
fi

TIMEOUT_SECOND=$1
BACK_TIME_SECOND=${TIMEOUT_SECOND}
BASE_DIR=$(dirname ${0})
SSH_KEY_FILE=${BASE_DIR}/key-root
REPORT_TMP=${BASE_DIR}/dfsadmin_report.tmp
RESTARTED_LOG=${BASE_DIR}/restarted_datanodes.log
WHITELIST="idc1-datanode11 idc1-datanode13"

hdfs dfsadmin -report | grep -E 'Hostname|Last contact' > ${REPORT_TMP}

function restart_datanode_service(){
  hostname=$1
  last_restarted_timestamp=$(grep -w ${hostname} ${RESTARTED_LOG} |tail -n 1 |awk '{print $2}')
  last_restarted_timestamp_back_second=$((${last_restarted_timestamp}+${BACK_TIME_SECOND}))
  now_timestamp=$(date +%s)
  if [ ${last_restarted_timestamp_back_second} -lt ${now_timestamp} ]; then
    echo "Restarting the DN on ${hostname} due to timeout ${last_contact_timeout_second} >= ${TIMEOUT_SECOND} second(s)"
    ssh -i ${SSH_KEY_FILE} -o StrictHostKeyChecking=no root@${hostname} 'pkill -kill -f proc_datanode'
    ssh -i ${SSH_KEY_FILE} -o StrictHostKeyChecking=no root@${hostname} 'ps aux | grep proc_datanode | grep -v grep || service hadoop-hdfs-datanode start'
    echo "${hostname} ${now_timestamp}" >> ${RESTARTED_LOG}
  fi
}

for hostname in $(grep -w Hostname ${REPORT_TMP} |awk '{print $NF}')
do
  if [ ! -z "$hostname" ]; then
    hostname_short=$(echo ${hostname} |cut -d. -f1)
    if ! $(echo ${WHITELIST} |grep -wq ${hostname_short}); then
      last_contact_time=$(grep -A1 ${hostname} ${REPORT_TMP} |grep 'Last contact' |awk -F "Last contact: " '{print $NF}')
      last_contact_timestamp=$(date -d "${last_contact_time}" +%s)
      now_timestamp=$(date +%s)
      last_contact_timeout_second=$((${now_timestamp}-${last_contact_timestamp}))
      if [ ${last_contact_timeout_second} -ge ${TIMEOUT_SECOND} ]; then
        restart_datanode_service ${hostname}
      fi
    fi
  fi
done
