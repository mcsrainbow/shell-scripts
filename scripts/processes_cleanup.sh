#!/bin/bash

# To kill the running processes older than 3 days

days_keep=3
days_keep_in_seconds=$((${days_keep}*24*3600))

echo "DATE: $(date)"

pid_items=$(/bin/ps -eo pid,args | grep -E '/path/to/program|ps.string.for.Program' | grep -vw grep | awk '{print $1}' | xargs)
for pid in ${pid_items}; do
  info_started=$(/bin/ps -p ${pid} -o lstart | grep -vw STARTED)
  info_user=$(/bin/ps -p ${pid} -o user | grep -vw USER)
  info_mem_k=$(/bin/ps -p ${pid} -o rss | grep -vw RSS)
  info_mem_g=$(echo "scale=2;${info_mem_k}/1024/1024" | /usr/bin/bc | sed 's/^\./0./')
  info_elapsed_in_seconds=$(/bin/ps -p ${pid} -o etime | grep -vw ELAPSED | tr '-' ':' | awk -F: '{total=0; m=1;} {for (i=0;i<NF;i++) {total+=$(NF-i)*m;m*=i>=2?24:60}} {print total}')
  if [[ ${info_elapsed_in_seconds} -gt ${days_keep_in_seconds} ]]; then
    echo "KILLED: USER:'${info_user}'           PID:'${pid}'    MEM:'${info_mem_g}G'    STARTED:'${info_started}'"
    /bin/kill -9 ${pid}
  else
    echo "PASSED: USER:'${info_user}'           PID:'${pid}'    MEM:'${info_mem_g}G'    STARTED:'${info_started}'"
  fi
done
