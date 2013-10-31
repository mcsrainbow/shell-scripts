#!/bin/bash

host_list=$(xe vm-list params | grep "Control domain on host: " | awk -F ": " '{print $3}'| cut -d . -f 1 | sort -n)

for host in $host_list
do
  guest_vm=$(ssh $host "xl list-vm |awk '{print \$3}'| grep -vw name | sort -n")
   
  t_mem_m=$(ssh $host 'xl info | grep total_memory | cut -d : -f 2')
  f_mem_m=$(ssh $host 'xl info | grep free_memory | cut -d : -f 2')
  t_mem_g=$(($t_mem_m/1024))
  f_mem_g=$(($f_mem_m/1024))
  
  disk_uuid=$(xe sr-list | grep -A 2 -B 1 "Local storage" | grep -B 3 "$host" | grep uuid | awk -F ": " '{print $2}')
  t_disk_b=$(xe sr-param-list uuid=$disk_uuid | grep physical-size | cut -d : -f 2)
  u_disk_b=$(xe sr-param-list uuid=$disk_uuid | grep physical-utilisation | cut -d : -f 2)
  f_disk_b=$(($t_disk_b-$u_disk_b))
  t_disk_g=$(($t_disk_b/1024/1024/1024))
  f_disk_g=$(($f_disk_b/1024/1024/1024))

  t_cpu_num=$(ssh $host 'xe host-cpu-info | grep -w cpu_count | awk -F ": " "{print \$2}"')
  v_cpu_sum=0
  for vm in $guest_vm
  do
    vm_uuid=$(xe vm-list | grep -B 1 -w $vm | head -n 1 | awk -F ": " '{print $2}')
    v_cpu_num=$(xe vm-list params=VCPUs-number uuid=${vm_uuid} | grep -w VCPUs | awk -F ": " '{print $2}')
    v_cpu_sum=$(($v_cpu_sum+$v_cpu_num))
  done
  f_cpu_num=$(($t_cpu_num-$v_cpu_sum))
   
  echo ""
  echo Host $host: $guest_vm
  echo "Available: Mem=${f_mem_g}/${t_mem_g}G  Disk=${f_disk_g}/${t_disk_g}G  CPU=${f_cpu_num}/${t_cpu_num}Cores"
done

