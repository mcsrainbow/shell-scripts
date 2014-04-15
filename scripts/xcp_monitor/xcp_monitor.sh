#!/bin/bash

function get_info(){
  host_name=$1
  host_uuid=$(xe host-list |grep -w ${host_name} -B1 |grep -w uuid |awk '{print $NF}')
  guest_vm=$(xe vm-list resident-on=${host_uuid} is-control-domain=false |grep -w name-label |awk '{print $NF}' |sort -n |xargs)
   
  t_mem_m=$(xe host-param-list uuid=${host_uuid} |grep -w memory-total |awk '{print $NF}')
  f_mem_m=$(xe host-param-list uuid=${host_uuid} |grep -w memory-free-computed |awk '{print $NF}')
  t_mem_g=$(($t_mem_m/1024/1024/1024))
  f_mem_g=$(($f_mem_m/1024/1024/1024))

  xe sr-list |grep -A2 -B3 -w ${host_name} |grep -A1 -B4 -Ew 'lvm|ext' |grep -w name-label |awk -F ': ' '{print $2}' > /tmp/sr_items.tmp
  disk_info=""
  while read sr_name
  do
    disk_uuid=$(xe sr-list |grep -A 2 -B 1 "$sr_name" |grep -B 3 -w "$host" |grep uuid |awk -F ": " '{print $2}')
    t_disk_b=$(xe sr-param-list uuid=$disk_uuid |grep physical-size |cut -d : -f 2)
    u_disk_b=$(xe sr-param-list uuid=$disk_uuid |grep physical-utilisation |cut -d : -f 2)
    f_disk_b=$(($t_disk_b-$u_disk_b))
    t_disk_g=$(($t_disk_b/1024/1024/1024))
    f_disk_g=$(($f_disk_b/1024/1024/1024))
    disk_info="${f_disk_g}/${t_disk_g}G $disk_info"
  done < /tmp/sr_items.tmp

  t_cpu_num=$(xe host-param-list uuid=${host_uuid} | grep -w 'cpu_count' | awk '{print $4}' | cut -d";" -f1)
  v_cpu_sum=0
  for vm in $guest_vm
  do
    vm_uuid=$(xe vm-list |grep -B 1 -w $vm |head -n 1 |awk -F ": " '{print $2}')
    v_cpu_num=$(xe vm-list params=VCPUs-number uuid=${vm_uuid} |grep -w VCPUs |awk -F ": " '{print $2}')
    v_cpu_sum=$(($v_cpu_sum+$v_cpu_num))
  done
  f_cpu_num=$(($t_cpu_num-$v_cpu_sum))
   
  echo "Host $host_name: \"$guest_vm\""
  echo "Available: \"Mem=${f_mem_g}/${t_mem_g}G  Disk=${disk_info} CPU=${f_cpu_num}/${t_cpu_num}Cores\""
}

if [ $# == 0 ]; then
  host_list=$(xe host-list |grep name-label |awk '{print $4}' |cut -d. -f1 |sort -n)
  for host_name in $host_list
  do
    echo "-------------------------------------------------------"
    get_info ${host_name}
  done
else
  get_info $1
fi
