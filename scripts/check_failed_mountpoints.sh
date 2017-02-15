#!/bin/bash
#
# Check failed mountpoints by writing temporary empty files
#

excluded_mountpoints_file=/var/tmp/excluded_mountpoints.txt
if [[ ! -f ${excluded_mountpoints_file} ]]; then
  touch ${excluded_mountpoints_file}
fi

all_mountpoints=$(/usr/bin/timeout 2 /bin/mount | grep -E '^/dev|:/' | awk '{print $2}' | sort | xargs)
for mountpoint_item in ${all_mountpoints}; do
  if ! $(grep -Eq ^${mountpoint_item}\$ ${excluded_mountpoints_file}); then
    touch ${mountpoint_item}/mountpoint.check.tmp 2>/dev/null
    if [[ $? -ne 0 ]]; then
      if [[ -z "${failed_mountpoints}" ]]; then
        failed_mountpoints="${mountpoint_item}"
      else
        failed_mountpoints="${failed_mountpoints},${mountpoint_item}"
      fi
    else
      rm ${mountpoint_item}/mountpoint.check.tmp
    fi
  fi
done

if [[ ! -z "${failed_mountpoints}" ]]; then
  echo "CRIT. Found Failed Mountpoints: ${failed_mountpoints}"
  exit 2
else
  excluded_mountpoints=$(cat ${excluded_mountpoints_file} | xargs | sed s/' '/,/g)
  if [[ ! -z "${excluded_mountpoints}" ]]; then
    echo "OK. Excluded mountpoints: ${excluded_mountpoints} in ${excluded_mountpoints_file}"
  else
    echo "OK"
  fi
  exit 0
fi
