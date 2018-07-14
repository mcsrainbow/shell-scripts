#!/bin/bash

# Check App Role Related Connections
# By Dong Guo 2016/08/10

declare -A abbr_dict=(
["cb"]="Couchbase"
["mc"]="Memcache"
["db"]="MySQLDB"
["zk"]="Zookeeper"
["kb"]="KafkaBroker"
)

function print_help(){
  echo "Usage:"
  echo "  ${0} -r ads -t cb|mc|db|zk|kb [-c /path/to/conf]"
  echo "  ${0} -r api -t cb|mc|db|kb [-c /path/to/conf]"
  echo ""
  echo "Examples:"
  echo "  ${0} -r ads -t zk"
  echo "  ${0} -r ads -t kb"
  echo "  ${0} -r api -t kb -c /path/to/kafkabroker.conf"
  echo ""
  echo "Abbreviations:"
  for key in "${!abbr_dict[@]}"; do
    raw_output="${raw_output}${key}:\'${abbr_dict["${key}"]}\' "
  done
  echo ${raw_output} | xargs -n 4 echo " "
  exit 1
}

function check_port(){
  host=$1
  port=$2
  conn_time=3
  
  /usr/bin/nc -w ${conn_time} -z ${host} ${port}
  if [[ $? -ne 0 ]]; then
    echo "${host}:${port}"
  fi
}

function check_mysql(){
  host=$1
  port=$2
  
  /usr/bin/mysqladmin -uuser -ppass -h${host} -P${port} ping | grep 'is alive'
  if [[ $? -ne 0 ]]; then
    echo "${host}:${port}"
  fi
}

function check_conn(){
  if ! $(echo ${allowed_conn} |grep -wq ${conn}); then
    echo "ERROR: The '${conn}' is not in the allowed_conn:'${allowed_conn}' for role:'${role}'"
    exit 1
  fi

  case "${conn}" in
    "mc")
      if [[ -z "${conf}" ]]; then
        conf="/path/to/memcache.conf"
      fi
      conn_list=$(grep -E '.*.memcache.hosts=' ${conf} |grep -v '^#' |awk -F '=' '{print $2}' |sed 's/,/ /g' |xargs -n 1 |sort |uniq)
      ;;
    "cb")
      if [[ -z "${conf}" ]]; then
        conf="/path/to/couchbase.conf"
      fi
      conn_list=$(grep 'couchbase.hosts=' ${conf} |grep -v '^#' |awk -F '=' '{print $2}' |sed 's/,/ /g' |xargs -n 1 |sort |uniq)
      ;;
    "db")
      if [[ -z "${conf}" ]]; then
        conf="/path/to/mysqldb.conf"
      fi
      conn_list=$(grep -E 'db.*.url' ${conf} |grep -v '^#' |awk -F 'jdbc:mysql://' '{print $2}' |cut -d/ -f1)
      ;;
    "zk")
      if [[ -z "${conf}" ]]; then
        conf="/path/to/zookeeper.conf"
      fi
      conn_list=$(grep 'zookeeper.connect=' ${conf} |grep -v '^#' |awk -F '=' '{print $2}' |cut -d/ -f1 |sed 's/,/ /g')
      ;;
    "kb")
      if [[ -z "${conf}" ]]; then
        conf="/path/to/kafkabroker.conf"
      fi
      conn_list=$(grep 'metadata.broker.list=' ${conf} |grep -v '^#' |awk -F '=' '{print $2}' |sed 's/,/ /g')
      ;;
  esac

  for conn_item in ${conn_list}; do
    host=$(echo ${conn_item} |cut -d: -f1)
    port=$(echo ${conn_item} |cut -d: -f2)
    raw_cmdout=$(check_port ${host} ${port})
    if ! $(echo ${raw_cmdout} |grep -wq succeeded); then
      if [[ -z "${err_cmdout}" ]]; then
        err_cmdout="${raw_cmdout}"
      else
        err_cmdout="${err_cmdout},${raw_cmdout}"
      fi
    fi
  done
 
  if [[ -z ${err_cmdout} ]]; then
    if $(echo "${conn}" |grep -Ewq 'db'); then
      for conn_item in ${conn_list}; do
        host=$(echo ${conn_item} |cut -d: -f1)
        port=$(echo ${conn_item} |cut -d: -f2)
        sql_cmdout=$(check_mysql ${host} ${port} |xargs)
        if ! $(echo ${sql_cmdout} |grep -q "is alive"); then
          if [[ -z "${err_cmdout}" ]]; then
            err_cmdout="${sql_cmdout}"
          else
            err_cmdout="${err_cmdout},${sql_cmdout}"
          fi
        fi
      done
    fi
  fi

  if [[ ! -z ${err_cmdout} ]]; then
    echo "CRIT. Failed to connect to ${abbr_dict["${conn}"]}:'${err_cmdout}'"
    exit 2
  else
    echo "OK. No failed ${abbr_dict["${conn}"]} connection"
    exit 0
  fi
}

while getopts "r:t:c:" opts; do
  case "${opts}" in
    "r")
      role=${OPTARG}
      ;;
    "t")
      conn=${OPTARG}
      ;;
    "c")
      conf=${OPTARG}
      ;;
    *)
      print_help
      ;;
  esac
done

if [[ -z "${role}" ]] || [[ -z "${conn}" ]]; then
  print_help
else
  case "${role}" in 
    "ads")
      allowed_conn="cb|mc|db|zk|kb"
      ;;
    "api")
      allowed_conn="cb|mc|db|kb"
      ;;
    "*")
      print_help
      ;;
  esac

  check_conn
fi
