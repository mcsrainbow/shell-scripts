#!/bin/bash

log_file=/opt/data/logs/mountpoint.txt

touch $log_file
chmod 644 $log_file

bucket_list=$(df -hP 2>&1 | grep -i "transport endpoint is not connected" | awk -F : '{print $2}' | sort | uniq | sed -n "s/\ \‘\//\//p" | sed -n "s/\’//p" | xargs)
for bucket in ${bucket_list};do
  num=$(ps aux | grep -c ${bucket})
  num_retry=$(($num+6))
  for n in $(seq $num_retry); do
    /bin/umount -f $bucket 2>&1 | tee -a $log_file
  done
  echo "Mountpoint: $bucket was not running well and remounted at $(date)" | tee -a $log_file
done

for i in $(cat /etc/fstab | grep s3fs | awk '{print $2}' | awk -F / '{print $NF}'); do
  if ! $(df -hP | grep -q $i); then
    echo "Mountpoint: $i was lost and remounted at $(date)" | tee -a $log_file
    s3fs $i /opt/data/sync/$i -o rw,allow_other,use_path_request_style,nonempty,url=https://s3-ap-east-1.amazonaws.com,dev,suid
  fi
done

if [ ! -z "${bucket_list}" ]; then
  sleep 30
  systemctl restart lsyncd 
  echo "Restarted lsyncd at $(date)" | tee -a $log_file
fi
