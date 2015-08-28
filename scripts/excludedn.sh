#!/bin/bash
#
# Exclude or recover a datanode from Hadoop cluster

conf=/etc/hadoop/conf/datanodes.exclude

function check_ha_status(){
  ha_status=$( hdfs haadmin -getServiceState ${1} )
  if [[ $? -ne 0 ]]; then
    echo "Error running 'hdfs haadmin -getServiceState ${1}'."
    exit 1
  fi

  if [[ "${ha_status}" == "active" ]]; then
    echo "${1} active"
    return
  fi

  echo "${1} standby"
  return
}

function get_excluded_datanodes(){
  for item in $(cat ${conf} | cut -d: -f1)
  do
    excluded_datanodes="${excluded_datanodes} $(host ${item} |awk '{print $NF}' |awk -F '.drawbrid.ge.' '{print $1}')"
  done
  echo ${excluded_datanodes} |xargs -n 5 echo ' '
}

function usage(){
  echo "Please run as root on ${master}."
  echo ""
  echo "Usage:"
  echo "  Exclude a datanode:"
  echo "    $0 <datanode>"
  echo "  Recover a datanode:"
  echo "    $0 -r <datanode>"
  echo ""
  echo "Current excluded datanodes:"
  get_excluded_datanodes
  exit 1
}

ha_status_a=( $( check_ha_status "idc1-hnn1" ) )
ha_status_b=( $( check_ha_status "idc1-hnn2" ) )

if [[ ${#ha_status_a[@]} -eq 0 || ${#ha_status_b[@]} -eq 0 ]]; then
  echo "Missing namenode(s), exiting..."
  exit 1
elif [[ "${ha_status_a[1]}" == "active" && "${ha_status_b[1]}" == "active" ]]; then
  echo "Both namenodes show active status, exiting..."
  exit 1
elif [[ "${ha_status_a[1]}" == "standby" && "${ha_status_b[1]}" == "standby" ]]; then
  echo "Both namenodes show standby status, exiting..."
  exit 1
fi

if [[ "${ha_status_a[1]}" == "active" ]]; then
  master="${ha_status_a[0]}"
  standby="${ha_status_b[0]}"
else
  master="${ha_status_b[0]}"
  standby="${ha_status_a[0]}"
fi

[[ "$(whoami)" == "root" ]] || usage
[[ "$(hostname -s)" == "${master}" ]] || usage
do_remove="false"

while getopts "hr:" option
do
  case $option in
    h)
      usage
      ;;
    r)
      dn=$OPTARG
      do_remove="true"
      ;;
    ?)
      usage
      ;;
  esac
done

if [[ -z "${dn}" ]]; then
  dn=${1}
fi
if [[ -z "${dn}" ]]; then
  usage
fi

if [[ "${do_remove}" == "false" ]]; then
  echo "Adding $dn to ${conf}..."
  dn_ip=$(host ${dn} |awk '{print $NF":50010"}')
  if ! $(grep -wq ${dn_ip} ${conf}); then
    echo "${dn_ip}" >> $conf
  fi
else
  dn_ip=$(host ${dn} |awk '{print $NF":50010"}')
  echo "Removing ${dn} from ${conf}..."
  sed -i "/^${dn_ip}/d" ${conf}
fi

if [[ "${standby}" != "NONE" ]]; then
  echo "Syncing the ${conf} to ${standby}"
  scp ${conf} root@${standby}:${conf}
  if [[ $? -eq 0 ]]; then
    echo "Refreshing the nodes..."
    hdfs dfsadmin -refreshNodes
    echo "Current excluded datanodes:"
    get_excluded_datanodes
  else
    echo "Failed to sync the ${conf} to ${standby}"
    exit 2
  fi
else
  echo "Refreshing the nodes..."
  hdfs dfsadmin -refreshNodes
  echo "Current excluded datanodes:"
  get_excluded_datanodes
fi
