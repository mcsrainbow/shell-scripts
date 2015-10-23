#!/bin/bash
#
# Output example: idc1-server1, X8STi, 1x4096 kB, 2x4096 MB, 4xNo Module Installed

hostname=$(hostname -s)
motherboard=$(dmidecode |grep "Product Name" |awk -F ': ' '{print $2}' |uniq |xargs)
ram_all=$(dmidecode |grep 'Memory Device' -A 5 |grep Size: |grep -v Range |awk -F ': ' '{print "x"$2}' |grep -v 'No Module Installed' |sort |uniq -c)
result=""
for i in ${ram_all}
do 
  if $(echo $i |grep -q 'x'); then
    result="$result$i"
  elif $(echo $i |grep -q 'B'); then
    result="$result $i, "
  else
    result="$result$i"
  fi
done

slots_open=$(dmidecode |grep 'Memory Device' -A 5 |grep Size: |grep -v Range |awk -F ': ' '{print $2}' |grep -c 'No Module Installed')

echo "${hostname}, ${motherboard}, ${result}${slots_open}xNo Module Installed"
