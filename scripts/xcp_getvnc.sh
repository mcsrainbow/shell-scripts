#!/bin/bash

vm=$1
if [ -z ${vm} ]; then
  echo "Usage: $0 vm_name"
  echo "VMs found:"
  xl list-vm | awk '{print $3}' | grep -vw name
  exit 1
fi

xe vm-list params=name-label name-label=${vm} | grep ${vm} > /dev/null
if [ $? -gt 0 ]; then
  echo "Error: invalid VM name"
  exit 1
fi

host=$(xe vm-list params=resident-on name-label=${vm} | grep resident-on | awk '{print $NF}')
dom=$(xe vm-list params=dom-id name-label=${vm} | grep dom-id | awk '{print $NF}')
port=$(xenstore-read /local/domain/${dom}/console/vnc-port)
ip=$(xe pif-list management=true params=IP host-uuid=${host} | awk '{print $NF}')

echo "run this on laptop and connect via vnc to localhost:${port}"
echo "--> ssh -L ${port}:localhost:${port} root@${ip}"
