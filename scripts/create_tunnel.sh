#!/bin/bash
# Create a SSH tunnel to access an unreachable web URL via another reachable host
# For Mac OS only

tunnel_host=${1}
dest_host_full_url=${2}

ssh_user="trump"
ssh_port=22
ssh_key="/Users/trump/.ssh/id_rsa"

if [[ $# -ne 2 ]] && [[ "${1}" != "list" ]]; then
  echo "Usage: ${0} tunnel_host dest_host_full_url"
  echo "       ${0} trump.heylinux.com http://tiffany.heylinux.com/#/pretty/girl"
  echo "       ${0} trump.heylinux.com https://ivanka.heylinux.com:8443/#/pretty/girl"
  echo "       ${0} list"
  exit 1
elif [[ "${1}" == "list" ]]; then
  if ! $(ps -e -o pid,command | grep -q '\-f \-N \-T \-L'); then
    echo "No SSH tunnel process running"
  else
    echo "PID   COMMAND"
    ps -e -o pid,command | grep '\-f \-N \-T \-L'
  fi
  exit 0
fi

dest_host_protocol=$(echo ${dest_host_full_url} | cut -d: -f1)
dest_host_name=$(echo ${dest_host_full_url} | cut -d: -f2 | cut -d/ -f3)
dest_host_port=$(echo ${dest_host_full_url} | cut -d: -f3 | cut -d/ -f1)
dest_host_short_url=$(echo ${dest_host_full_url} | cut -d: -f3 | cut -d/ -f2-)

if ! $(echo "${dest_host_protocol}" | grep -Ewq 'http|https'); then
  echo "Need to specify the protocol in dest_host_full_url: 'http://' or 'https://'"
  exit 1
fi

if [[ -z "${dest_host_port}" ]]; then
  if [[ ${dest_host_protocol} == "http" ]]; then
    dest_host_port=80
  elif [[ ${dest_host_protocol} == "https" ]]; then
    dest_host_port=443
  fi
  dest_host_short_url=$(echo ${dest_host_full_url} | cut -d: -f2 | cut -d/ -f4-)
fi

# Use a different port on localhost for ports which less than 10,000
if [[ ${dest_host_port} -lt 10000 ]]; then
  local_host_port=$((${dest_host_port}+10000))
else
  local_host_port=${dest_host_port}
fi

ssh -i ${ssh_key} -p ${ssh_port} -l ${ssh_user} -f -N -T -L ${local_host_port}:${dest_host_name}:${dest_host_port} ${tunnel_host}

echo "Opening ${dest_host_protocol}://localhost:${local_host_port}/${dest_host_short_url}"
open ${dest_host_protocol}://localhost:${local_host_port}/${dest_host_short_url}
