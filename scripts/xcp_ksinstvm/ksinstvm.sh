#!/bin/bash
# Dong Guo
# Last Modified: 2013/11/28

# Note:
# The IP address configs in "ks_args" and "remote kickstart file" should be same
# And the IP address should be in the same subnet as the current xenserver,
# otherwise it failed if through the gateway

vm_name=t_c64_min
repo_url=http://172.16.4.11/repo/centos/6/
ks_args="ip=172.16.4.254 netmask=255.255.252.0 gateway=172.16.4.1 ns=172.16.4.10 noipv6 ks=http://172.16.4.11/repo/ks/centos-6.4-x86_64-minimal.ks ksdevice=eth0"
cpu_cores=4
mem_size=8G
disk_size=20G

echo "Creating an empty vm:${vm_name}..."
hostname=$(hostname -s)
sr_uuid=$(xe sr-list | grep -A 2 -B 1 "Local storage" | grep -B 3 -w "${hostname}" | grep uuid | awk -F ": " '{print $2}')
vm_uuid=$(xe vm-install new-name-label=${vm_name} sr-uuid=${sr_uuid} template=Other\ install\ media)
  
echo "Setting up the bootloader,cpu,memory..."
xe vm-param-set VCPUs-max=${cpu_cores} uuid=${vm_uuid}
xe vm-param-set VCPUs-at-startup=${cpu_cores} uuid=${vm_uuid}
xe vm-memory-limits-set uuid=${vm_uuid} dynamic-min=${mem_size}iB dynamic-max=${mem_size}iB static-min=${mem_size}iB static-max=${mem_size}iB
xe vm-param-set HVM-boot-policy="" uuid=${vm_uuid}
xe vm-param-set PV-bootloader="eliloader" uuid=${vm_uuid}

echo "Setting up the kickstart..."
xe vm-param-set other-config:install-repository="${repo_url}" uuid=${vm_uuid}
xe vm-param-set PV-args="${ks_args}" uuid=${vm_uuid}

echo "Setting up the disk..."
xe vm-disk-add uuid=${vm_uuid} sr-uuid=${sr_uuid} device=0 disk-size=${disk_size}iB
vbd_uuid=$(xe vbd-list vm-uuid=${vm_uuid} userdevice=0 params=uuid --minimal)
xe vbd-param-set bootable=true uuid=${vbd_uuid}

echo "Setting up the network..."
network_uuid=$(xe network-list bridge=xenbr0 --minimal)
xe vif-create vm-uuid=${vm_uuid} network-uuid=${network_uuid} mac=random device=0

echo "Starting the vm:${vm_name}" 
xe vm-start vm=${vm_name}